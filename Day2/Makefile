Day2: Day2.o
	ld -o Day2 Day2.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -arch arm64

Day2.o:
	as -arch arm64 -o Day2.o Day2.s
