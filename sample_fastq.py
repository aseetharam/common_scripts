from __future__ import division
import random
import argparse
import sys

parser = argparse.ArgumentParser()
parser.add_argument("input", help="input FASTQ filename")
parser.add_argument("output", help="output FASTQ filename")
parser.add_argument("-f", "--fraction", type=float, help="fraction of reads to sample")
parser.add_argument("-n", "--number", type=int, help="number of reads to sample")
parser.add_argument("-s", "--sample", type=int, help="number of output files to write", default=1)
args = parser.parse_args()

if args.fraction and args.number:
   sys.exit("give either a fraction or a number, not both")

if not args.fraction and not args.number:
   sys.exit("you must give either a fraction or a number")

print("counting records....")
with open(args.input) as input:
    num_lines = sum([1 for line in input])
total_records = int(num_lines / 4)

if args.fraction:
    args.number = int(total_records * args.fraction)

print("sampling " + str(args.number) + " out of " + str(total_records) + " records")

output_files = []
output_sequence_sets = []
for i in range(args.sample):
    output_files.append(open(args.output + "." + str(i), "w"))
    output_sequence_sets.append(set(random.sample(xrange(total_records + 1), args.number)))

record_number = 0
with open(args.input) as input:
        for line1 in input:
            line2 = input.next()
            line3 = input.next()
            line4 = input.next()
            for i, output in enumerate(output_files):
                if record_number in output_sequence_sets[i]:
                        output.write(line1)
                        output.write(line2)
                        output.write(line3)
                        output.write(line4)
            record_number += 1
            if record_number % 100000 == 0:
                print(str((record_number / total_records) * 100)  + " % done")


for output in output_files:
    output.close()
print("done!")
print("want to learn how to write useful tools like this? Go to http://pythonforbiologists.com/books")
