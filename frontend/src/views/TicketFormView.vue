<template>
  <div v-if="loading" class="page-state" role="status">Loading ticket form…</div>
  <p v-else-if="error && !data" class="error-message" role="alert">{{ error }}</p>
  <div v-else-if="data" class="narrow-page">
    <p class="eyebrow"><RouterLink :to="`/projects/${route.params.projectId}`">{{ data.project.name }}</RouterLink> / {{ editing ? "Edit ticket" : "New ticket" }}</p>
    <div class="page-heading compact-heading"><div><h1>{{ editing ? "Edit ticket" : "Create a ticket" }}</h1><p class="lede">Give the team a clear next action.</p></div></div>
    <form class="quick-form ticket-form" @submit.prevent="save"><p v-if="error" class="error-message" role="alert">{{ error }}</p><label>Title<input v-model="form.title" required autofocus /></label><label>Description<textarea v-model="form.description" rows="6" /></label><div class="form-grid"><label>Status<select v-model="form.status"><option v-for="status in data.statuses" :key="status.value" :value="status.value">{{ status.label }}</option></select></label><label>Assignee<select v-model="form.assignee_id"><option value="">Unassigned</option><option v-for="user in data.users" :key="user.id" :value="user.id">{{ user.name }}</option></select></label></div><div class="form-actions"><RouterLink class="button button-quiet" :to="`/projects/${route.params.projectId}`">Cancel</RouterLink><button class="button button-primary" type="submit">{{ editing ? "Save changes" : "Create ticket" }}</button></div></form>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue"
import { RouterLink, useRoute, useRouter } from "vue-router"
import { api } from "../api"

const route = useRoute()
const router = useRouter()
const editing = computed(() => Boolean(route.params.ticketId))
const data = ref(null)
const form = ref({ title: "", description: "", status: "todo", assignee_id: "" })
const error = ref("")
const loading = ref(true)

async function load() {
  loading.value = true
  error.value = ""
  try {
    data.value = await api.getTicketForm(route.params.projectId, route.params.ticketId)
    form.value = { ...data.value.ticket, assignee_id: data.value.ticket.assignee_id || "" }
  } catch (exception) {
    error.value = exception.message
  } finally {
    loading.value = false
  }
}
async function save() {
  error.value = ""
  try {
    const result = editing.value ? await api.updateTicket(route.params.projectId, route.params.ticketId, form.value) : await api.createTicket(route.params.projectId, form.value)
    await router.push(result.redirect_url.replace(/^.*\/projects\//, "/projects/"))
  } catch (exception) { error.value = exception.message }
}

watch(() => route.fullPath, load)
onMounted(load)
</script>

<style scoped>
.page-state { margin: 0 auto; max-width: 920px; padding: 36px 0; }
</style>
