
windres -v resource.rc resource.o
windres -v --target=pe-x86-64 resource.rc resource_x64.o
pause