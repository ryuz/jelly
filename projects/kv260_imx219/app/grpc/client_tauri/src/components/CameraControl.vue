


<template>

<div>camera address : <input v-model="cameraUrl"><button @click="onConnect">Connect</button> </div>
<br>
<br>

<div class="slider">
<div class="slider_text">width</div>
<div class="slider_input"><input type="range" min="16" max="2048" step="16" v-model="aoiWidth"></div>
<div class="slider_value">{{ aoiWidth }}</div>
</div>

<div class="slider">
<div class="slider_text">height</div>
<div class="slider_input"><input type="range" min="16" max="1024" step="16" v-model="aoiHeight"></div>
<div class="slider_value">{{ aoiHeight }}</div>
</div>

<div class="slider">
<div class="slider_text">aoi-x</div>
<div class="slider_input"><input type="range" min="16" max="2048" step="16" v-model="aoiX"></div>
<div class="slider_value">{{ aoiX }}</div>
</div>

<div class="slider">
<div class="slider_text">aoi-y</div>
<div class="slider_input"><input type="range" min="16" max="1024" step="16" v-model="aoiY"></div>
<div class="slider_value">{{ aoiY }}</div>
</div>

<div class="slider">
<div class="slider_text">aoi-y</div>
<div class="slider_input"><input type="range" min="16" max="1024" step="16" v-model="aoiY"></div>
<div class="slider_value">{{ aoiY }}</div>
</div>

<div class="item">
<div class="item_text">set aoi</div>
<div class="item_main"><button @click="onSetAoi">reflect</button></div>
</div>

<div class="slider">
<div class="slider_text">analog-gain</div>
<div class="slider_input"><input type="range" min="0.0" max="20.0" step="0.1" v-model="analogGain"> </div>
<div class="slider_value">{{ analogGain }}</div>
</div>

<div class="slider">
<div class="slider_text">digital-gain</div>
<div class="slider_input"><input type="range" min="0.0" max="20.0" step="0.1" v-model="digitalGain">  </div>
<div class="slider_value">{{ digitalGain }}</div>
</div>

<div class="item">
<div class="item_text">flip-h</div>
<div class="item_main"><input type="checkbox" v-model="flipH"></div>
</div>

<div class="item">
<div class="item_text">flip-v</div>
<div class="item_main"><input type="checkbox" v-model="flipV"></div>
</div>

<div class="slider">
<div class="slider_text">bayer-phase</div>
<div class="slider_input"><input type="range" min="0" max="3" step="1" v-model="bayerPhase"></div>
<div class="slider_value">{{ bayerPhase }}</div>
</div>


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


.item {
  display: flex;
  align-content: space-evenly;
}
.item_text {
    width: 10em;
}
.item_main {
    width: 100px; 
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
    width: 10em;
}


</style>
