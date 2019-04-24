@echo off
mingw64\bin\windres -v --target=pe-i386 resource.rc resource.o
mingw64\bin\windres -v --target=pe-x86-64 resource.rc resource_x64.o
pause