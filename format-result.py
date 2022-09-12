#!/usr/bin/python3
import os
import re

fin = open("bughunt-result.txt", "r")
fout = open("result.txt", "w+")

lines = fin.readlines()

for line in lines:
    if "Unaccounted allocation" in line:
        tmprecord = line
        continue
    if "Unaccounted paths" in line:
        if tmprecord != "":
            fout.write(tmprecord)
            tmprecord = ""
        fout.write(line)
        continue
    if "-> " in line:
        fout.write(line)

fout.close()
fin.close()
