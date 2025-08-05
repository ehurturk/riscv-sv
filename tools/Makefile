CC = g++
CXXFLAGS = 
CXX_VERSION = 17

SRCS = simulator.cpp simulator_gui.cpp
LIBS = -lcurses
TARGET = simulator

.PHONY: all clean

all: build


build:
	$(CC) $(SRCS) -std=c++$(CXX_VERSION) -o $(TARGET) $(LIBS)

clean:
	@rm -rf simulator
