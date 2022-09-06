
<template>
<p>analog-gain</p>
<p><input type="range" min="0.0" max="20.0" step="0.1" v-model="analogGain"></p>
<p> {{ analogGain }}</p>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { invoke } from "@tauri-apps/api/tauri";
import AppVue from "../App.vue";

const analogGain = ref<Number>(20.0)

watch(analogGain, async () => {
    console.log("analogGain")
    await invoke("set_gain", {id:1, gain: parseFloat(analogGain.value)});
})


</script>
  
<style scoped>
.canvas {
    border: 1px solid #000;
}
</style>
