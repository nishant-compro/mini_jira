<template>
  <div class="page-heading"><div><p class="eyebrow">Workspace / Projects</p><h1>All projects</h1><p class="lede">A focused view of the work moving through your team.</p></div><button class="button button-primary" type="button" @click="showForm = !showForm">＋ New project</button></div>
  <form v-if="showForm" class="quick-form" @submit.prevent="createProject"><div class="form-heading"><div><p class="eyebrow">Start something new</p><h2>Create a project</h2></div><button class="icon-button" type="button" aria-label="Close" @click="showForm = false">×</button></div><p v-if="error" class="error-message" role="alert">{{ error }}</p><label>Project name<input v-model="form.name" required autofocus /></label><label>Description<textarea v-model="form.description" rows="3" /></label><button class="button button-primary" type="submit">Create project</button></form>
  <div v-if="projects.length" class="project-grid"><RouterLink v-for="project in projects" :key="project.id" class="project-card" :to="`/projects/${project.id}`"><div class="project-card-top"><span class="project-icon">{{ project.name.slice(0, 1).toUpperCase() }}</span><span class="arrow">↗</span></div><h2>{{ project.name }}</h2><p>{{ project.ticket_count }} tickets · {{ project.open_tickets_count }} open</p><div class="progress"><span :style="{ width: `${project.ticket_count ? Math.max(12, (project.open_tickets_count / project.ticket_count) * 100) : 0}%` }" /></div></RouterLink></div>
  <div v-else class="empty-state"><span class="empty-icon">✦</span><h2>Your workspace is clear</h2><p>Create your first project to give the team somewhere to work.</p></div>
</template>

<script setup>
import { ref } from "vue"
import { RouterLink } from "vue-router"
import { api } from "../api"

const props = defineProps({ projects: { type: Array, default: () => [] } })
const emit = defineEmits(["project-created"])
const showForm = ref(false)
const form = ref({ name: "", description: "" })
const error = ref("")

async function createProject() {
  error.value = ""
  try {
    const project = await api.createProject(form.value)
    form.value = { name: "", description: "" }
    showForm.value = false
    emit("project-created", project)
  } catch (exception) { error.value = exception.message }
}
</script>

<style scoped>
.quick-form { max-width: 650px; }
</style>
