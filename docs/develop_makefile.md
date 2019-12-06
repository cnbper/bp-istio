# makefile

## GCC编译的使用方式

```shell
cat > main.c<<EOF
#include <stdio.h>
int main()
{
      printf("hello word");
      return 0;
}
EOF
# 编译
gcc -c main.c

# GCC链接,生成可执行程序
gcc -o main main.o
./main
```

- GCC静态链接的使用方式

```shell
# 创建一个第三方库的文件“static.h”
cat > static.h<<EOF
void testStatic();
EOF
# 实现文件"static.c"
cat > static.c<<EOF
#include <stdio.h>
#include "static.h"
void testStatic()
{
    printf("testStatic\n");
}
EOF
# 将static.c打包成静态库
gcc -c static.c
ar rc libstatic.a static.o
# 引入静态库的main1.c
cat > main1.c<<EOF
#include <stdio.h>
#include "static.h"
int main()
{
    testStatic();
    return 0;
}
EOF
# 编译 main1.c，连接main1.o，并且将静态库引入进来
gcc -c main1.c
gcc -o main1 main1.o -L./ -lstatic
./main1
```

- GCC动态链接的使用方式

```shell
# 创建动态库源文件头文件share.h
cat > share.h<<EOF
void testShare();
EOF
# 创建动态库源文件头文件share.c
cat > share.c<<EOF
#include <stdio.h>
#include "share.h"
void testShare()
{
    printf("testShare\n");
}
EOF
# 将share.c编译成动态库
# 参数解释：-shared表示编译成动态库 -fPIC一般都用这个参数，表示编译的动态库以后被引用的时候使用的是相对位置
gcc -fPIC -shared share.c -o libshare.so
# 创建引用动态库的源文件main2.c
cat > main2.c<<EOF
#include <stdio.h>
#include "share.h"

int main()
{
    testShare();
    return 0;
}
EOF
# 编译main2.c，并引入动态链接库
gcc -c main2.c
gcc -o main2 main2.o -L./ -lshare
./main2
```

- GCC静态链接+动态链接混用的方式

```shell
# 首先创建源码文件main3.c
cat > main3.c<<EOF
#include <stdio.h>
#include "static.h"
#include "share.h"

int main()
{
    testStatic();
    testShare();
    return 0;
}
EOF
# 编译并连接main3.c，同时引入静态和动态库
gcc -c main3.c
gcc -o main3 main3.o -L./ -lshare -lstatic
./main3
```

## Makefile的规则

- ISTIO_GO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

```shell
$(MAKEFILE_LIST)
```
