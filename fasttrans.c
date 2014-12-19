/* FASTTRANS.C
28-JUL-2000, David Mathog, Biology Division, Caltech

Added optional second parameter = minimum size of orfs to
output.  If present, then each ORF >= this minimum size
is output as a separate FASTA entry.  

Also modified code so that if it finds an entry > 1Mb
it will automatically split it into 2 (or more) pieces.

30-MAY-2000, David Mathog, Biology Division, Caltech

Simple program that translates one or more frames in a DNA fasta
file to protein.  Default is to do all 6 frames.  Input
from stdin and output to stdout, always.  The one argument is
123456 where 1->3 are the 3 forward frames and 4->6 the three
reverse frames.  Specify as many as are desired in the translation.
For instance, infile:

>example
ACGCTCTCTCT

becomes
>example-1for
translation
>example-2for
translation
>example-3for
translation
>example-1rev
translation
>example-2rev
translation
>example-3rev
translation

Maximum input sequence length is 1Mb.  To change that see the
MAXSEQIN parameter, below.

*/

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>  /* for toupper */
#include <string.h> /* for strlen and such */
#include <unistd.h>

#define AVAL 0
#define CVAL 1
#define GVAL 2
#define TVAL 3

#define MAXSEQIN 1000000
#define MAXHEADER 1000
#define MAXOUTLINE 50
#define FRAGOVERLAP 498  /* MUST be multiple of 3 or the frame shifts!!! */

#define FOR1   1
#define FOR2   2
#define FOR3   4
#define REV1   8
#define REV2  16
#define REV3  32

typedef struct transrec ATRANSREC;
struct transrec {
  char    aa;
  char    nt[4];
};

char inseq[MAXSEQIN];
char accumseq[MAXSEQIN];
char outtrans[1 + MAXSEQIN/3 ];
char header[MAXHEADER];
char holdheader[MAXHEADER];
int frames;
int acclen;
int minaa;

ATRANSREC alltrans[64]={
    { 'K' ,  "AAA"  },
    { 'N' ,  "AAC"  },
    { 'K' ,  "AAG"  },
    { 'N' ,  "AAT"  },
    { 'T' ,  "ACA"  },
    { 'T' ,  "ACC"  },
    { 'T' ,  "ACG"  },
    { 'T' ,  "ACT"  },
    { 'R' ,  "AGA"  },
    { 'S' ,  "AGC"  },
    { 'R' ,  "AGG"  },
    { 'S' ,  "AGT"  },
    { 'I' ,  "ATA"  },
    { 'I' ,  "ATC"  },
    { 'M' ,  "ATG"  },
    { 'I' ,  "ATT"  },
    { 'Q' ,  "CAA"  },
    { 'H' ,  "CAC"  },
    { 'Q' ,  "CAG"  },
    { 'H' ,  "CAT"  },
    { 'P' ,  "CCA"  },
    { 'P' ,  "CCC"  },
    { 'P' ,  "CCG"  },
    { 'P' ,  "CCT"  },
    { 'R' ,  "CGA"  },
    { 'R' ,  "CGC"  },
    { 'R' ,  "CGG"  },
    { 'R' ,  "CGT"  },
    { 'L' ,  "CTA"  },
    { 'L' ,  "CTC"  },
    { 'L' ,  "CTG"  },
    { 'L' ,  "CTT"  },
    { 'E' ,  "GAA"  },
    { 'D' ,  "GAC"  },
    { 'E' ,  "GAG"  },
    { 'D' ,  "GAT"  },
    { 'A' ,  "GCA"  },
    { 'A' ,  "GCC"  },
    { 'A' ,  "GCG"  },
    { 'A' ,  "GCT"  },
    { 'G' ,  "GGC"  },
    { 'G' ,  "GGA"  },
    { 'G' ,  "GGG"  },
    { 'G' ,  "GGT"  },
    { 'V' ,  "GTA"  },
    { 'V' ,  "GTC"  },
    { 'V' ,  "GTG"  },
    { 'V' ,  "GTT"  },
    { '*' ,  "TAA"  },
    { 'Y' ,  "TAC"  },
    { '*' ,  "TAG"  },
    { 'Y' ,  "TAT"  },
    { 'S' ,  "TCA"  },
    { 'S' ,  "TCC"  },
    { 'S' ,  "TCG"  },
    { 'S' ,  "TCT"  },
    { '*' ,  "TGA"  },
    { 'C' ,  "TGC"  },
    { 'W' ,  "TGG"  },
    { 'C' ,  "TGT"  },
    { 'L' ,  "TTA"  },
    { 'F' ,  "TTC"  },
    { 'L' ,  "TTG"  },
    { 'F' ,  "TTT"  }
};

/* PROTOTYPES */
void sendout(int offset, char * string);
void translate(int offset);
void minaaout(char* string);
void orfout(char *orf);
void process_dna_seq(void);

/* translates the specified frame from nucleotides to amino acids */


void translate(int offset){
int i,j,k;
char *fptr;
int index;
int count;

  outtrans[0]='\0';
  
  for(fptr=&accumseq[offset],count=1,i=0,j=0,index=0 ; ; count++,j++,fptr++){
    
    k = 1 << 2*(2-j);
    
    if(*fptr == '\0'){ /* emit the final fragment, if any */
      outtrans[i]='\0';
      return;
    }
    else {
      
      switch (*fptr){
        case 'A':
          index += (k * AVAL);
          break;
        case 'C':
          index += (k * CVAL);
          break;
        case 'G':
          index += (k * GVAL);
          break;
        case 'T':
          index += (k * TVAL);
          break;
        default:
          index=1000;        
      } /* switch */
      if(j==2){
        j=-1;
        if(index < 64){
          outtrans[i]=alltrans[index].aa;
        }
        else {
          outtrans[i]='X';
        }
        index=0;
        i++;
      }
    }
  }
}

/* orfout sends the designated ORF string to stdout in chunks
of MAXOUTLINE characters (plus a terminator).  It needs write
access to the ORF string, but it doesn't change anything
permanently */

void orfout(char *orf){
int front,back,count;
char hold;

  for(front=back=0,count=1; ;back++,count++){
  
    /* end of buffer writes out a line so long as that line
       is not empty (just a zero byte).  It cannot
       be > MAXOUTLINE due to the logic of this routine */
       
    if(orf[back] == '\0'){
      if(count != 1)(void) fprintf(stdout,"%s\n",&orf[front]);
      break;
    }
    
    /* if MAXOUTLINE characters are at hand send them out now */
    
    if(count>MAXOUTLINE){
      hold=orf[back];
      orf[back]='\0';
      (void) fprintf(stdout,"%s\n",&orf[front]);
      orf[back]=hold;
      front=back;
      count=1;
    }
  }
}

/* minaaout scans the outtrans buffer for ORFs >= minaa
   and uses orfout to emit those it finds */
    
void minaaout( char* string){
int retval;
int i,done;
int front,back;

   retval=0;
   for (front=back=0, i=1,done=0 ; done != 1 ; back++){
     switch(outtrans[front]){
        case '*':
           front++;
           back=front;
           break;
        case '\0':
           done=1;
           break;
        default:
           switch(outtrans[back]){
              case '\0':  /* have an ORF, this INTENTIONALLY FALLS THROUGH */
                done = 1; 
              case '*':   /* have an ORF */
                outtrans[back]='\0';  /* terminate this piece */
                if(back-front >= minaa){  /*  satisfies length criterion */
                    (void)fprintf(stdout,"%s%s_%.6d\n",header,string,i);
                    orfout(&outtrans[front]);
                    i++;
                }
                front=back;
                front++;
                back++;
                break;
              default:
                break;
           }
           break;
     }
   }
}

/* sendout translates the specified frame. And then causes the translation
to be written out in full (if minaa <=0 ) or as ORFs (minaa > 0) */
 
void sendout(int offset, char * string){

  translate(offset);
  
  if(minaa > 0){
    minaaout(string);
  }
  else{
    (void)fprintf(stdout,"%s%s\n",header,string);
    orfout(outtrans);
  }
}

 /* process_dna_seq first strips out everything except XNACGTU.- 
    all of which may be in the sequence. It also converts 
    U to T if any are found.  Then it calls sendout for each of the
    specified frames*/

void process_dna_seq(void){
char *from;
char *to;
int count;
char flip[256];
char hold;
int i,j;

 if(acclen <=0 )return;
 
 
 count=0;
 for(from=to=accumseq; *from!='\0'; from++){
   *from=toupper(*from);
   switch (*from){
     case 'A':
     case 'C':
     case 'G':
     case 'T':
       *to=*from;
       to++;
       count++;
       break;
     case 'U':
       *to='T';
       to++;
       count++;
       break;
     case '.':
     case '-':
     case 'N':
     case 'X':
       *to='X';
       to++;
       count++;
       break;
   }
 }
 *to='\0';
 
 /* now do the various frames */
 
 if(frames & FOR1)sendout(0,"-for1");
 if(frames & FOR2)sendout(1,"-for2");
 if(frames & FOR3)sendout(2,"-for3");
 
 /*  complement the sequence */
 for(i=0; i<256; i++){
   flip[i]='X';
 }
 flip['A']='T';
 flip['C']='G';
 flip['G']='C';
 flip['T']='A';

 for(i=0 ; i<count ; i++){
   accumseq[i]=flip[accumseq[i]];
 }
 for(i=0,j=count-1 ; i<=j ; i++,j--){
   hold=accumseq[j];
   accumseq[j]=accumseq[i];
   accumseq[i]=hold;
 }

 if(frames & REV1)sendout(0,"-rev1");
 if(frames & REV2)sendout(1,"-rev2");
 if(frames & REV3)sendout(2,"-rev3");
 
}

int main(int argc, char *argv[]){
char *fptr;
char *to;
int toolong;

  if(argc < 2 || argc > 3){
    (void) fprintf(stderr," usage (UNIX):     fasttrans 123456 [minAA] <in.nfa >out.pfa \n");
    (void) fprintf(stderr," usage (OpenVMS):  pipe fasttrans 123456 [minAA] <in.nfa >out.pfa \n");
    (void) fprintf(stderr,"    input is a fasta dna sequence via stdin\n");
    (void) fprintf(stderr,"    output is the translated protein sequence via stdout\n");
    (void) fprintf(stderr,"    Specify the set of frames to translate on command line\n");
    (void) fprintf(stderr,"       1,2,3 are the 3 forward frames\n");
    (void) fprintf(stderr,"       4,5,6 are the 3 reverse frames\n");
    (void) fprintf(stderr,"    minAA is an optional value.  If present and greater than zero\n");
    (void) fprintf(stderr,"       it emits each ORF that has at least that many AA residues\n");
    (void) fprintf(stderr,"       in it as a separate fasta fragment.  If not present or set to zero\n");
    (void) fprintf(stderr,"       or less the entire translated frame is emitted\n");
    exit(EXIT_FAILURE);
  }

  /* figure out the frames we will process */
  frames=0;
  for(fptr=argv[1]; *fptr != '\0'; fptr++){
    switch (*fptr){
      case '1':
        frames |= FOR1;
        break;
      case '2':
        frames |= FOR2;
        break;
      case '3':
        frames |= FOR3;
        break;
      case '4':
        frames |= REV1;
        break;
      case '5':
        frames |= REV2;
        break;
      case '6':
        frames |= REV3;
        break;
      default:
        (void) fprintf(stderr,"FASTTRANS: fatal error:  invalid frame specified [%s]\n",fptr);
        exit(EXIT_FAILURE);
    } /* switch(*fptr) */
  } /* for on *fptr */
  
  if(argc==3){
     if(sscanf(argv[2],"%d",&minaa) != 1){
        (void) fprintf(stderr,"FASTTRANS: fatal error:  invalid minaa specified [%s]\n",argv[2]);
        exit(EXIT_FAILURE);
     }
  }
  else{
     minaa=0;
  }
  
  /* start reading */
  fptr=inseq;
  acclen=0;
  toolong=0;
  while(fptr != NULL){
    fptr = fgets(inseq,MAXSEQIN-1,stdin);
    if(fptr != NULL){
      /* store the header */
      if(*fptr=='>'){
        process_dna_seq(); /* only if acclen > 0 */
        for(to=header; (*fptr != ' ' && *fptr != '\0' && *fptr != '\t' && *fptr != '\n' && *fptr != '\r'); fptr++,to++){
           *to=*fptr;
        }
        *to='\0';
        accumseq[0]='\0';
        acclen=0;
        toolong=0;
      }
      else {
        if(strlen(inseq) + acclen > MAXSEQIN){
          if(acclen < 3*FRAGOVERLAP){
            (void) fprintf(stderr,"FASTTRANS: fatal error:  excessively long input line\n");
            exit(EXIT_FAILURE);
          }

          /* store the header and process the big piece we already have */

          if(toolong==0){
            (void) strcpy(holdheader,header);
            toolong++;  /* number chunks from 1 */
          }
          
          /* this allows up to 10000 separately numbered fragments of size
             one million.  Unlikely there will ever be a single DNA sequence
             longer than 10 GB! */
          
          (void) sprintf(header,"%s.frag%.4d",holdheader,toolong);
          toolong++;
          process_dna_seq(); /* only if acclen > 0 */

          /* save the last FRAGOVERLAP bases, and adjust acclen.
             The strncpy should be safe as there will be no overlap
             of the copied piece.  */

          (void) strncpy(accumseq,&accumseq[acclen-FRAGOVERLAP],FRAGOVERLAP);
          accumseq[FRAGOVERLAP]='\0';  /* be sure that it's terminated */
          acclen=FRAGOVERLAP;
        }
        (void) strcat(accumseq,inseq);
        acclen += strlen(inseq);
      } /* ftp test on '>' */
    } /* ftpr != NULL (valid read) */
  } /* while(fptr != NULL) */
  if(acclen != 0){
    if(toolong != 0)(void) sprintf(header,"%s.frag%.4d",holdheader,toolong);
    process_dna_seq();
  }
  exit(EXIT_SUCCESS);
}
