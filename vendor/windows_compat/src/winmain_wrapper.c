// Provide a WinMain that calls main() for console apps
#ifdef _WIN32
#include <windows.h>

extern int main(int argc, const char **argv);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nCmdShow;
    return main(__argc, (const char**)__argv);
}
#endif
