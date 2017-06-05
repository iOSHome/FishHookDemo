//
//  main.m
//  FishhookDemo
//
//  Created by lichuanjun on 2017/6/5.
//  Copyright © 2017年 lichuanjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fishhook.h"

static int (*original_open)(const char *, int, ...);

// 1. 重新实现 new_open 函数===============================================================
int new_open(const char *path, int oflag, ...) {
    va_list ap = {0};
    mode_t mode = 0;
    
    if ((oflag & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_start(ap, oflag);
        mode = va_arg(ap, int);
        va_end(ap);
        printf("Calling real open('%s', %d, %d)\n", path, oflag, mode);
        return original_open(path, oflag, mode);
    } else {
        printf("Calling real open('%s', %d)\n", path, oflag);
        return original_open(path, oflag, mode);
    }
}

// 2. 官方使用代码===============================================================
static int (*orig_close)(int);
static int (*orig_open)(const char *, int, ...);

int my_close(int fd) {
    printf("Calling real close(%d)\n", fd);
    return orig_close(fd);
}

int my_open(const char *path, int oflag, ...) {
    va_list ap = {0};
    mode_t mode = 0;
    
    if ((oflag & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_start(ap, oflag);
        mode = va_arg(ap, int);
        va_end(ap);
        printf("Calling real open('%s', %d, %d)\n", path, oflag, mode);
        return orig_open(path, oflag, mode);
    } else {
        printf("Calling real open('%s', %d)\n", path, oflag);
        return orig_open(path, oflag, mode);
    }
}
//========================================================================

// 3. 不能修改非动态链接库===============================================================
/*
 1. fishhook 在 dyld 加载镜像时，插入了一个回调函数，交换了原有函数的实现；
 2. fishhook 不能修改非动态链接库：开发人员自己手写的函数
 */
void hello() {
    printf("hello\n");
}

static void (*original_hello)();

void new_hello() {
    printf("New_hello\n");
    original_hello();
}

//========================================================================


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 1. 重新实现 new_open 函数==================
//        struct rebinding open_rebinding = { "open", new_open, (void *)&original_open };
//        rebind_symbols((struct rebinding[1]){open_rebinding}, 1);
//        __unused int fd = open(argv[0], O_RDONLY);
        
        // 2. 官方使用代码==================
//        rebind_symbols((struct rebinding[2]){{"close", my_close, (void *)&orig_close}, {"open", my_open, (void *)&orig_open}}, 2);
//        
//        int fd = open(argv[0], O_RDONLY);
//        uint32_t magic_number = 0;
//        read(fd, &magic_number, 4);
//        printf("Mach-O Magic Number: %x \n", magic_number);
//        close(fd);
        
        // 3. 不能修改非动态链接库==================
        struct rebinding open_rebinding = { "hello", new_hello, (void *)&original_hello };
        rebind_symbols((struct rebinding[1]){open_rebinding}, 1);// fishhook 对这种手写的函数是没有作用的
        hello();
    }
    return 0;
}
