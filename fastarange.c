/* FASTARANGE.C
14-DEC-2000, David Mathog, Biology Division, Caltech

Selects from a FASTA file read in from STDIN entries FIRST through LAST
and emits them to STDOUT.  If the file does not have at least FIRST
entries the program exits with an error.  No input line may exceed 1M 
characters.  If LAST is negative then it's absolute value represents
a number of entries.

Arguments are:

 1:  FIRST first record to process
 2:  LAST  last record to process

optional arguments are

 3:  START  first base/aa to emit
 4:  END    last  base/aa to emit

both must be present or absent.  Emits only that range of characters.
It's a fatal error to emit 0 characters of sequence.

18-FEB-2010, David Mathog
  Increased string buffer to 1M from 100K.  Some headers are over 400K now!
10-APR-2003, David Mathog
  Remove trailing CR if present.  Makes it less sensitive to Unix
  vs. Windows files.
13-NOV-2002, David Mathog
  DONE wasn't initialized.  Intel compiler didn't preset it to 0 which
  caused fragment length calculation to fail.  Gcc and Sun C must have
  autoinitialized it to zero.
12-MAR-2002, David Mathog,
  added DONE so that single extraction from a large fasta file exits when
  the character range is done.
  Fixed bug in sanity checking with LAST=0
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#define MYMAXSTRING 1000000
int main(int argc, char *argv[]){
char bigstring[MYMAXSTRING];
char *newline;
char *cout;
char *cptr;
int  FIRST,LAST,fragcount,ecount;
int  START,END,DONE,ccount,bad;
enum statetype  {BEFORE,IN,AFTER};
enum statetype state;
  
  ccount    = 1;
  fragcount = 0;
  ecount    = 0;
  FIRST     = 0;
  LAST      = 0;
  START     = 1;
  END       = 0;
  bad       = 0;
  state     = AFTER;
  DONE      = 0;
  if(  argc == 3 &&
    (
      (sscanf(argv[1],"%d",&FIRST)==EOF) ||
      (FIRST < 1)                        ||
      (sscanf(argv[2],"%d",&LAST)==EOF)  ||
      (LAST > 0 && LAST < FIRST)
    )
  ){ bad = 1;}
  if( argc == 5 &&
    (
      (sscanf(argv[1],"%d",&FIRST)==EOF) ||
      (FIRST < 1)                        ||
      (sscanf(argv[2],"%d",&LAST)==EOF)  ||
      (LAST > 0 && LAST < FIRST)        ||
      (sscanf(argv[3],"%d",&START)==EOF) ||
      (START < 1)                        ||
      (sscanf(argv[4],"%d",&END)==EOF)   ||
      (END > 0 && END < START)
    )
  ){ bad = 1;}
  if(argc !=3 && argc !=5){ bad=1;}
  if(bad){
    (void) printf("Usage:  fastarange FIRST last [start end] <file (output to stdout)\n");
    (void) printf("    FIRST is the number of the first entry to emit (1 emits first record)\n");
    (void) printf("    LAST  (LAST>0) is the number of the last  entry to emit\n");
    (void) printf("          (LAST<0) is the number of entries (-5 -> emit 5 beginning with FIRST)\n");
    (void) printf("          (LAST=0) emit all entries to end AFTER FIRST\n");
    (void) printf("    Optional arguments, both must be present together\n");
    (void) printf("    START is the first sequence character to emit (1 emits first record)\n");
    (void) printf("    END   (END>0) is the number of the last character to emit\n");
    (void) printf("          (END<0) is the number of characters  (-5 -> emit 5 characters with START)\n");
    (void) printf("          (END=0) emit all entries to end AFTER first\n");
    (void) printf(" Examples:\n");
    (void) printf("   $ fastarange 10  15 <foo.pfa    (emits  6 entries, 10 through 15, inclusive)\n");
    (void) printf("   $ fastarange 10 -15 <foo.pfa    (emits 15 entries, 10 through 24, inclusive)\n");
    (void) printf("   $ fastarange 10 -15 20 30 <foo.pfa    (emits 15 entries, 10 through 24, characters 20 through 30, inclusive)\n");
    exit(EXIT_FAILURE);
  }
  
  if(LAST < 0 )LAST = FIRST - LAST -1;
  if(END  < 0 )END  = START - END  -1;
  while( fgets(bigstring,MYMAXSTRING,stdin) != NULL){
    newline=strstr(bigstring,"\n");
    if(newline == NULL){   /* string truncated */
      (void) fprintf(stderr,"FASTARANGE input record exceeds 1M characters\n"); 
      (void) fprintf(stderr,"FASTARANGE failed.  %d fragments emitted\n",ecount);
      exit(EXIT_FAILURE);
    }
    *newline='\0';  /* replace the \n with a terminator */
    newline--;
    if(newline>=bigstring && *newline=='\r')*newline='\0';
    
    if(bigstring[0] == '>'){
      if(state == BEFORE){
        (void) fprintf(stderr,"FASTARANGE failed.  Character range resulted in zero length sequence\n");
        (void) fprintf(stderr,"  %d fragments emitted\n",ecount);
        exit(EXIT_FAILURE);
      }
      fragcount++;
      if(fragcount >= FIRST){
         state=BEFORE;
         ccount=1;
      }
      if(LAST != 0){
        if(fragcount > LAST){ break; }
      }
      if(fragcount >= FIRST){
         ecount++;
         (void) fprintf(stdout,"%s\n",bigstring);
      }
      continue;
    }
    if(fragcount >= FIRST){
      /* the final character will be a LF unless the line was too long
         which would indicate an error */


      if(START==1 && END==0){ /* no character filtering */
        (void) fprintf(stdout,"%s\n",bigstring);
        state = IN;
      }
      else{ /* character filtering */
        switch (state) {
          case BEFORE:
             if(END==0){
               for(cout=NULL,cptr=bigstring; *cptr; cptr++,ccount++){
                 if(ccount == START){
                   cout=cptr;
                   state = IN;
                 }
               }
             }
             else{
               for(cout=NULL,cptr=bigstring; *cptr; cptr++,ccount++){
                 if(ccount == START){
                   cout=cptr;
                   state = IN;
                 }
                 if(ccount == END + 1){
                   *cptr='\0';
                   state = AFTER;
                 }
               }
             }
            if(cout!=NULL){  (void) fprintf(stdout,"%s\n",cout); }
            break;
          case IN:  /* at least one line already emitted */
            if(END == 0){
               (void) fprintf(stdout,"%s\n",bigstring);
               break;
            }
            /* line starts at first character, looking for explicit end */        
            for(cout=cptr=bigstring; *cptr; cptr++,ccount++){
              if(ccount == END + 1){
                *cptr='\0';
                state = AFTER;
                break;
              }
            }
            (void) fprintf(stdout,"%s\n",cout);
            break;
          case AFTER:
            if(LAST != 0 && fragcount>=LAST)DONE=1;
            break; /* nothing left to emit */
	  default:
	    fprintf(stderr,"FASTARANGE: Fatal programming error\n");
	    exit(EXIT_FAILURE);
        } /* end of switch */
      } /* end of else for character filtering */
    } /* end of condition fragcount >= FIRST */
    if(DONE)break;
  } /* end of reading loop */
  if(fragcount < FIRST){
     (void) fprintf(stderr,"FASTARANGE failed.  %d fragments emitted\n",ecount);
     exit(EXIT_FAILURE);
  }
  else{
     (void) fprintf(stderr,"FASTARANGE completed successfully.  %d fragments emitted\n",ecount);
     exit(EXIT_SUCCESS);
  }
}
