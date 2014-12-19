#include <iostream>
#include <fstream>
#include <ctime>
#include "api/BamReader.h"
#include "api/BamWriter.h"

using namespace std;
using namespace BamTools;

// Bin of 20 bp for insert size dist
#define BIN 100
// Max insert value in dist
#define MAX_V 15000
// Max index value in dist
#define MAX_I MAX_V/BIN

// Array of length MAXV/BIN with all values
// initialized to zero
int dist [MAX_I+1] = {0};


int main(int argc, char* argv[])
{
    // Reading input parameter (BAM file)
    string inputBamFile;
    char * outputPath;


    if ( argc == 3 )
    {
        inputBamFile  = argv[1];
        outputPath    = argv[2];
    }
    else
    {
        cerr << "Wrong number of arguments. Requires 2." << endl;
        cerr << "Input BAM & output file path." << endl;
        return 1;
    }

    // Open the BAM file for reading
    BamReader reader;
    if (!reader.Open(inputBamFile))
    {
        cerr << "Could not open input BAM file." << endl;
        return 1;
    }

    // Opening output file for writing
    char outputFile [200];
    strcpy (outputFile,outputPath);
    strcat (outputFile,"/insertSizeDist.txt");
    ofstream outfile (outputFile);
    if ( !outfile )
    {
           // outfile is bad
           cerr << "Bad output filename : " << outputFile << endl;
           return EXIT_FAILURE;
    }


    time_t myTime = time(NULL);
    cout << asctime(localtime(&myTime));
    cout << "Generating Insert Size Distribution...";


    // Now processing each record of the BAM file
    BamAlignment al;

    int count = 0;

    while (reader.GetNextAlignment(al)) {

        int32_t tag;
        int32_t insertSize;
        int index;

        if (al.IsPaired())
        {

            if (al.IsFirstMate())
            {

                if (al.IsMapped())
                {

                    if (al.IsMateMapped())
                    {
                        count++;
                        insertSize = abs(al.InsertSize);
                        index = insertSize/BIN;
                        if (index > MAX_I) { index = MAX_I; }
                        dist[index]++;
                    }
                }
            }
        }    
    }
    reader.Close();

    // Now printing the distribution to output file
    outfile << ">>INSERT_SIZE_DISTRIBUTION" << endl;
    outfile << "RANGE\tVALUE" << endl;

    int i;
    short int inf;
    short int sup;

    for(i=0; i < MAX_I; i++)
    {
        inf = i*BIN;
        sup = (i+1)*BIN-1;
        outfile << inf << "_" << sup << "\t" << dist[i] << endl;
    }

    inf = MAX_I*BIN;
    outfile << inf << "_" << "INF" << "\t" << dist[MAX_I] << endl;
    outfile.close();

    cout << "done." << endl;
    cout << count << " pairs used (both reads mapped)." << endl;
    myTime = time(NULL);
    cout << asctime(localtime(&myTime));

    return 0;
}
