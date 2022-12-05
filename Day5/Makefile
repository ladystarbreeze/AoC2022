Day5: Day5.o
	ld -o Day5 Day5.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -arch arm64

Day5.o:
	as -arch arm64 -o Day5.o Day5.s
