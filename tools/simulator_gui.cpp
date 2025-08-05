#include "simulator_gui.h"

#include <ncurses.h>

SimulatorGUI::SimulatorGUI() {
}

SimulatorGUI::~SimulatorGUI() {
    endwin();
}

void SimulatorGUI::init_screen() {
    initscr();
    raw();
    keypad(stdscr, TRUE);
    noecho();

    printw("Welcome to simulator!");


    refresh();
    getch();
    endwin();
}