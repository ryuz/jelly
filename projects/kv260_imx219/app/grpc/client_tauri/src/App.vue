<script setup lang="ts">
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://vuejs.org/api/sfc-script-setup.html#script-setup
//import Greet from "./components/Greet.vue";
import ImageView from "./components/ImageView.vue";
import CameraControl from "./components/CameraControl.vue";
</script>

<template>
  <div class="container">
    <h1>Kria KV260 IMX219 Camera Control</h1>
    <CameraControl />
    <ImageView />
  </div>
</template>

<style scoped>
.logo.vite:hover {
  filter: drop-shadow(0 0 2em #747bff);
}

.logo.vue:hover {
  filter: drop-shadow(0 0 2em #249b73);
}
</style>
