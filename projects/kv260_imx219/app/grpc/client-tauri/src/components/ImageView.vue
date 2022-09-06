
<template>
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

const imgWidth  = ref(640)
const imgHeight = ref(480)

const canvasRef = ref<HTMLCanvasElement>()
let ctx: CanvasRenderingContext2D
let callbackId: number = 0

async function get_image(id: number): Promise<ImageData> {
    let [w,  h, img]: [number, number, number[]] = await invoke("get_image", {id: id});
//    console.log(w)
//    console.log(h)
//    console.log(img)
    imgWidth.value = w
    imgHeight.value = h
    let array = new Uint8ClampedArray(img);
    let imgData = new ImageData(array, w, h)
    return imgData
}

async function set_aoi(width: number, height: number) {
    await invoke("set_aoi", {width: width, height:height, x:-1, y:-1});
}

onMounted(() => {
    ctx = canvasRef.value?.getContext('2d')!
    callbackId = requestAnimationFrame(moveAnimation)
    set_aoi(imgWidth.value, imgHeight.value)
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

const draw = async () => {
    let imgData = await get_image(1)
    ctx.putImageData(imgData, 0, 0)
}

const animation = async () => {
    await draw();
//  callbackId = requestAnimationFrame(moveAnimation)
//  setTimeout(() => {requestAnimationFrame(moveAnimation)}, 1000)
}


</script>
  
<style scoped>
.canvas {
    border: 1px solid #000;
}
</style>
