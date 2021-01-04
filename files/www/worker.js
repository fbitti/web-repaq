var fastqFileBlob = null;
var myFiles = [];

var Module = {
    noInitialRun: true,
    onRuntimeInitialized: async () => {
        FS.mkdir('/data');
        FS.mount(WORKERFS, {
            files: myFiles
        }, '/data');
        var startTime = new Date().getTime();

        // Run repaq
        await Module.ccall('wasm_repaq','void',[],[]);
        var repaqDuration = (new Date().getTime() - startTime)/1000;
        console.log("Repaq took ", repaqDuration, "seconds");
        console.log("data.rfq exists after execution of repaq: ", FS.analyzePath("data.rfq").exists);

        // Run xz
        startTime = new Date().getTime();
        await Module.ccall('wasm_xz','void',[],[]);
        var XZDuration = (new Date().getTime() - startTime)/1000;
        console.log("XZ took ", XZDuration, "seconds");
        console.log("data.rfq.xz exists after execution of xz: ", FS.analyzePath("data.rfq.xz").exists);

        let compressedBlobURL = URL.createObjectURL(
            new Blob(
                [
                    Module.FS.readFile("data.rfq.xz")
                ], 
                {
                    type: "application/octet-stream"
                }
            )
        );
        self.postMessage({
            blobURL: compressedBlobURL,
            repaqDuration: repaqDuration,
            XZDuration: XZDuration
        });
    }
};

// in a WebWorker, we represent scope using self instead of window
self.onmessage = msg => {
    myFiles = [];
    myFiles.push(new File([msg.data], "data.fastq")); 
    self.importScripts("main-module.js"); 
}