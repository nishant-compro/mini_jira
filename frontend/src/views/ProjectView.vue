<template>
  <div v-if="loading" class="page-state" role="status">Loading project…</div>
  <p v-else-if="error" class="error-message" role="alert">{{ error }}</p>
  <template v-else-if="data">
    <div class="page-heading board-heading">
      <div><p class="eyebrow"><RouterLink to="/projects">Projects</RouterLink> / {{ data.project.name }}</p><h1>{{ data.project.name }}</h1><p class="lede">{{ data.project.description || "Keep the next important thing moving." }}</p></div>
      <RouterLink class="button button-primary" :to="`/projects/${data.project.id}/tickets/new`">＋ New ticket</RouterLink>
    </div>
    <div class="board"><section v-for="status in statuses" :key="status" class="board-column"><div class="column-heading"><h2>{{ labels[status] }}</h2><span>{{ ticketsFor(status).length }}</span></div><div class="ticket-stack"><article v-for="ticket in ticketsFor(status)" :key="ticket.id" class="ticket-card"><RouterLink :to="`/projects/${data.project.id}/tickets/${ticket.id}`"><span class="ticket-id">MINI-{{ ticket.id }}</span><h3>{{ ticket.title }}</h3><p v-if="ticket.description">{{ ticket.description }}</p></RouterLink><div class="ticket-meta"><span v-if="ticket.assignee" class="avatar avatar-small">{{ ticket.assignee.initials }}</span><span v-else class="unassigned">Unassigned</span><button class="icon-button danger-button" type="button" aria-label="Delete ticket" @click="removeTicket(ticket)">×</button></div></article><div v-if="!ticketsFor(status).length" class="column-empty">No tickets here yet.</div></div></section></div>
  </template>
</template>

<script setup>
import { onMounted, ref, watch } from "vue"
import { RouterLink, useRoute } from "vue-router"
import { api } from "../api"

const route = useRoute()
const data = ref(null)
const error = ref("")
const loading = ref(true)
const statuses = ["todo", "in_progress", "done"]
const labels = { todo: "To do", in_progress: "In progress", done: "Done" }

async function load() {
  loading.value = true
  error.value = ""
  try { data.value = await api.getProject(route.params.projectId) } catch (exception) { error.value = exception.message } finally { loading.value = false }
}
async function removeTicket(ticket) {
  if (!window.confirm(`Delete “${ticket.title}”?`)) return
  await api.deleteTicket(route.params.projectId, ticket.id)
  await load()
}
function ticketsFor(status) { return data.value?.tickets.filter((ticket) => ticket.status === status) || [] }

watch(() => route.params.projectId, load)
onMounted(load)
</script>

<style scoped>
.page-state { padding: 36px 0; }
</style>
