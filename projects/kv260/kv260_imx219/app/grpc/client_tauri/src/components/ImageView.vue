
<template>
    <div> frame : {{ frameNum }}</div>
    <div>
    <canvas :width="imgWidth" :height="imgHeight" ref="canvasRef"></canvas>
    </div>
    <div>{{ imgWidth }} x {{ imgHeight }}</div>
    <button v-on:click="refleshImage">reflesh</button>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { invoke } from "@tauri-apps/api/tauri";
import AppVue from "../App.vue";

const imgWidth  = ref(1280)
const imgHeight = ref(720)
const frameNum = ref(0)

const canvasRef = ref<HTMLCanvasElement>()
let ctx: CanvasRenderingContext2D
let callbackId: number = 0

function base64decode(data:string){
    return new Uint8Array([...atob(data)].map(s => s.charCodeAt(0)));
}

/*
async function get_image(id: number): Promise<ImageData> {
    frameNum.value++;
//    let [w,  h, img]: [number, number, number[]] = await invoke("get_image", {id: id});
    let [w,  h, enc]: [number, number, string] = await invoke("get_image", {id: id});
    let img = base64decode(enc);
//    console.log(w)
//    console.log(h)
//    console.log(img)
    imgWidth.value = w;
    imgHeight.value = h;
    let array = new Uint8ClampedArray(img);
    let imgData = new ImageData(array, w, h);
    return imgData;
}
*/

async function get_image(id: number): Promise<string> {
    frameNum.value++;
//    let [w,  h, img]: [number, number, number[]] = await invoke("get_image", {id: id});
    let [w, h, img_str]: [number, number, string] = await invoke("get_image", {id: id});
    imgWidth.value = w;
    imgHeight.value = h;
    return img_str;
}

//async function set_aoi(width: number, height: number) {
//    await invoke("set_aoi", {id:1, width: width, height:height, x:-1, y:-1});
//}


onMounted(() => {
    ctx = canvasRef.value?.getContext('2d')!
    callbackId = requestAnimationFrame(moveAnimation)
//  set_aoi(imgWidth.value, imgHeight.value)
})

onBeforeUnmount(() => {
    cancelAnimationFrame(callbackId)
})

const refleshImage = () => {
    draw();
}

const moveAnimation = () => {
    animation()
};

/*
const draw = async () => {
    let imgData = await get_image(1)
    ctx.putImageData(imgData, 0, 0)
}
*/
const draw = async () => {
    let img_str = await get_image(1)
    var img = new Image();
//    img.src = "data:image/png;base64," + img_str;
    img.src = img_str;
    img.onload = () => {
        ctx.drawImage(img, 50, 0);
    };
//    ctx.putImageData(imgData, 0, 0)
}

const animation = async () => {
    await draw();
    callbackId = requestAnimationFrame(moveAnimation)
//  setTimeout(() => {callbackId = requestAnimationFrame(moveAnimation)}, 10)
}


</script>
  
<style scoped>
.canvas {
    margin:0 auto;
    text-align: center;
    border: 1px solid #000;
}
</style>
