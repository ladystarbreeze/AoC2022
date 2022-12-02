Day1: Day1.o
	ld -o Day1 Day1.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -arch arm64

Day1.o:
	as -arch arm64 -o Day1.o Day1.s
