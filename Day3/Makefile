Day3: Day3.o
	ld -o Day3 Day3.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -arch arm64

Day3.o:
	as -arch arm64 -o Day3.o Day3.s
