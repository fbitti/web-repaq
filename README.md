# web-repaq
By porting https://github.com/OpenGene/repaq CLI to WebAssembly, made possible with emscripten, you can now run Repaq on the browser.

The purpose of this repo is to show a working example of the porting, which you may study and modify in order to fit your projects.

# How repaq works
Repaq is a tool to compress FASTQ files. FASTQ files are used in bioinformatics projects to store DNA sequences. 

The important thing we need to know now is: these files can be huge, as large as several GBs, and compressing saves lots of storage space.

However, files compressed with repaq can be as small as 1/5 of what you would get with a general compression tool, like tar.gz, gzip or xz.

Because FASTQ follows a specific pattern, repaq is able to accomplish this by preprocessing them and creating an equivalent RFQ file in a format that can be much more efficiently compressed by xz.

# How web-repaq was created
In order to port the repaq functionality to the browser, it was necessary to port 2 tools to wasm (which is how I will call WebAssembly from now on).
- repaq itself is written in C++, and is available here: https://github.com/OpenGene/repaq.
- xz can be found here: https://tukaani.org/xz/. It is written in C and depends on liblzma, so, for a successful porting it was necessary to first port liblzma and, only after that, xz.

Emscripten is the tool used to port these projects to wasm, and is published here: https://github.com/emscripten-core/emscripten.
There are lots of flags to set emscripten compilation options, but from a design perspective, the following ones were fundamental:
- both tools must share the same filesystem
- your website must be able to run the tools inside a web worker if you don't want to see your browser's tab freeze while they work on it
- focus on the compression, so I modified repaq and xz main source files to specifically run 1 command each:

```bash
repaq -i /data/data.fastq -o /data.rfq
xz -z -k data.rfq
```

# Instructions
This repo provides a Dockerfile which compiles repaq to wasm and even serves a simple website, with a sample FASTQ website.

The reason I chose to do it by docker is because the emscripten project already provides a working container at https://hub.docker.com/u/emscripten, which simplifies your life as you do not need to install emscripten from scratch.

So the first step is to get Docker installed on your computer: https://docs.docker.com/get-docker/, and then follow these steps:

```bash
git clone https://github.com/fbitti/web-repaq.git
cd web-repaq
docker build -t web-repaq .
docker run -dt --name web-repaq -p 12380:80 web-repaq
docker exec -it web-repaq service nginx start
```

The `docker build` step takes several minutes, so be patient.

Now, point your browser to http://localhost:12380/ and follow the instructions. The website is really simple because it is just a proof-of-concept.

Go ahead and compress the sample 1MB FASTQ file. Save the resulting `_data.rfq.xz` file to your local `repaq` directory, and you may confirm the file compressed on the web and decompressed on the command line really matches the original file:

```bash
./repaq -d -i _data.rfq.xz -o _data.fastq
curl -O localhost:12380/1MB.fastq
cmp _data.fastq 1MB.fastq
```

# A sample implementation
In order to demo the concept even further and let you test your own FASTQ files on a better looking website, check this out:

https://web-repaq.web.app/

The largest file I was able to process myself had almost 2GB. It was the SRR494099.fastq from https://www.ebi.ac.uk/ena/browser/view/SRR494099 (HeLa). It took about 24 minutes of total processing time on a MacBook PRO with 16GB RAM and 8 cores, resulting in a 391 MB rfq.xz file.

# Thank you!
Porting other people's project is not an easy task, when you think you finally succeeded you suddenly meet another roadblock and gets back to a lot of research (Google and the emscripten forum are your friends).

Without being a C programmer myself, I learned a lot about C compilation guidelines, and how it is different when compiling C++ code.

At the end, it is worth seeing the goal we propose to ourselves is finally reached!

However, honestly I couldn't do it alone, so I must give credits to a few people who helped me on the way:
- [Robert Aboukhalil](https://github.com/robertaboukhalil): all of this started when I did Robert's course on WebAssembly, available on https://www.levelupwasm.com/ (not an affiliate link), it gave me the experience of porting multiple tools, starting from the simplest ones, which was a fundamental head start when trying to port a more complex project like this one.
Here is where you may see more bioinformatics tools ported by Robert to wasm: https://cdn.biowasm.com/

- [Alon Zakai](https://github.com/kripken) and [wilkie](https://github.com/wilkie)
Back in July, 2020, I was facing my last roadblock to complete this project, and decided to ask the emscripten community, as you may see here: 
https://github.com/emscripten-core/emscripten/issues/11621.

Alon is the creator of emscripten, and I was really impressed how present he was in guiding me through the possible reasons of the failure. Thank you! You are an inspiration on how to run an open source project!

wilkie figured out which flag was missing on my emconfigure command. After months being simply stuck, with his tip I was finally able to compile XZ and finish this project.
