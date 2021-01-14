FROM emscripten/emsdk:2.0.9 as builder
RUN apt update && apt -y upgrade && apt install -y libz-dev
RUN cd /src && git clone https://github.com/OpenGene/repaq
WORKDIR /src/repaq
RUN git checkout db65c0e
COPY files/repaq-src/main.cpp src/main.cpp
RUN emmake make repaq CXX=emcc CXXFLAGS="-s USE_ZLIB=1 -s USE_PTHREADS=0 $CXXFLAGS -fPIC -s ASSERTIONS=1"
RUN emcc ./obj/*.o -o repaq.wasm -s INVOKE_RUN=0 -s USE_ZLIB=1 -s USE_PTHREADS=0 -s EXPORTED_FUNCTIONS="['_wasm_repaq']" -s FORCE_FILESYSTEM=1 -s ASSERTIONS=1 -s SIDE_MODULE=2 -lworkerfs.js
WORKDIR /src
RUN curl -L -o /src/xz-5.2.5.tar.gz https://tukaani.org/xz/xz-5.2.5.tar.gz && \
tar xvf xz-5.2.5.tar.gz && \
rm xz-5.2.5.tar.gz
WORKDIR /src/xz-5.2.5
RUN emconfigure ./configure --enable-threads=no --disable-nls --disable-shared
WORKDIR /src/xz-5.2.5/src/liblzma
RUN emmake make CFLAGS="-g -Oz -fPIC -s USE_PTHREADS=0 -s EXPORT_ALL=1 -s ASSERTIONS=1"
COPY files/xz-src/main.c /src/xz-5.2.5/src/xz/main.c
WORKDIR /src/xz-5.2.5/src/xz
RUN emmake make CFLAGS="-g -Oz -s LLD_REPORT_UNDEFINED -s ERROR_ON_UNDEFINED_SYMBOLS=0 -fPIC -s DETERMINISTIC=1 -s USE_PTHREADS=0 -s ASSERTIONS=1"
COPY files/emscripten/pre.js /src/xz-5.2.5/src/xz/pre.js
WORKDIR /src/xz-5.2.5/src/xz
RUN emcc -fvisibility=hidden -Wall -Wextra -Wvla -Wformat=2 -Winit-self -Wmissing-include-dirs -Wstrict-aliasing -Wfloat-equal -Wundef -Wshadow -Wpointer-arith -Wbad-function-cast -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wold-style-definition -Wmissing-prototypes -Wmissing-declarations -Wmissing-noreturn -Wredundant-decls -g -Oz -fPIC -s USE_PTHREADS=0 *.o  ../../src/liblzma/.libs/liblzma.a -s EXPORTED_FUNCTIONS="['_wasm_xz','_main']" -s "EXTRA_EXPORTED_RUNTIME_METHODS=['ccall']" -s FORCE_FILESYSTEM=1 -s MAIN_MODULE=1 -s ALLOW_MEMORY_GROWTH=1 -o xz.html --pre-js pre.js -s ASSERTIONS=1 -s INVOKE_RUN=0 -lworkerfs.js

FROM nginx:1.19.6-alpine
LABEL maintainer="https://github.com/fbitti"
COPY files/nginx/mime.types /etc/nginx/mime.types
COPY files/nginx/site.conf /etc/nginx/conf.d/
COPY --from=builder /src/repaq/repaq.wasm /var/www/html/
COPY --from=builder /src/xz-5.2.5/src/xz/xz.js /var/www/html/main-module.js
COPY --from=builder /src/xz-5.2.5/src/xz/xz.wasm /var/www/html/xz.wasm
RUN rm /etc/nginx/conf.d/default.conf
COPY files/www/* /var/www/html/
