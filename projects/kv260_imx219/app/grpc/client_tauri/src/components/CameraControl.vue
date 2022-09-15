


<template>

<div>camera address : <input v-model="cameraUrl"><button @click="onConnect">Connect</button> </div>

<div class="slider">
<div class="slider_text">width</div>
<div class="slider_input"><input type="range" maxlength="200" min="16" max="2048" step="16" v-model="aoiWidth"></div>
<div class="slider_value">{{ aoiWidth }}</div>
</div>


<p>height       : <input type="range" min="16" max="1024" step="16" v-model="aoiHeight"> {{ aoiHeight }}</p>
<p>aoi-x        : <input type="range" min="16" max="2048" step="16" v-model="aoiX">      {{ aoiX }}</p>
<p>aoi-y        : <input type="range" min="16" max="1024" step="16" v-model="aoiY">      {{ aoiY }}</p>
<label>set aoi : <button @click="onSetAoi">reflect</button></label>

<p>analog-gain  : <input type="range" min="0.0" max="20.0" step="0.1" v-model="analogGain">  {{ analogGain }}</p>
<p>digital-gain : <input type="range" min="0.0" max="20.0" step="0.1" v-model="digitalGain"> {{ digitalGain }}</p>

<p> flip-h<input type="checkbox" v-model="flipH"></p>
<p> flip-v<input type="checkbox" v-model="flipV"></p>

<p>bayer-phase  : <input type="range" min="0" max="3" step="1" v-model="bayerPhase">      {{ bayerPhase }}</p>

</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { invoke } from "@tauri-apps/api/tauri";
import AppVue from "../App.vue";

const cameraUrl = ref("http://kria:50051")
const aoiWidth  = ref("640")
const aoiHeight = ref("480")
const aoiX  = ref("-1")
const aoiY  = ref("-1")

const analogGain  = ref("20.0")
const digitalGain = ref("0.0")

const flipH  = ref(false)
const flipV  = ref(false)

const bayerPhase = ref("0")


async function set_aoi() {
    await invoke("set_aoi",  {id:1, width: parseInt(aoiWidth.value), height: parseInt(aoiHeight.value), x: parseInt(aoiX.value), y: parseInt(aoiY.value)});
}

async function set_gain() {
    await invoke("set_gain", {id:1, gain: parseFloat(analogGain.value)});
}

async function set_digital_gain() {
    await invoke("set_digital_gain", {id:1, gain: parseFloat(digitalGain.value)});
}

async function set_flip() {
    await invoke("set_flip", {id:1, flipH: flipH.value, flipV: Boolean(flipV.value)});
}

async function set_bayer_phase() {
    await invoke("set_bayer_phase", {id:1, phase: parseInt(bayerPhase.value)});
}


const onConnect = async () => {
    await invoke("connect",  {id:1, url: cameraUrl.value});
    await set_aoi();
    await set_gain();
    await set_digital_gain();
};

const onSetAoi = async () => {
    await set_aoi();
};

//watch(aoiWidth, async () => { set_aoi(); })
//watch(aoiHeight, async () => { set_aoi(); })
//watch(aoiX, async () => { set_aoi(); })
//watch(aoiY, async () => { set_aoi(); })

watch(analogGain, async () => { set_gain(); })
watch(digitalGain, async () => { set_digital_gain(); })
watch(flipH, async () => { set_flip(); })
watch(flipV, async () => { set_flip(); })
watch(bayerPhase, async () => { set_bayer_phase(); })


</script>
  
<style scoped>
.canvas {
    border: 1px solid #000;
}

.slider {
  display: flex;
  align-content: space-evenly;
}

.slider_text {
    width: 10em;
}
.slider_input {
    width: 200px; 
}
.slider_value {
    width: 10%;
}


</style>
