<template>
  <div v-if="loading" class="page-state" role="status">Loading ticket…</div>

  <div v-else-if="error" class="page-state error-message" role="alert">
    <p>{{ error }}</p>
    <RouterLink class="button button-quiet" :to="`/projects/${route.params.projectId}`">Back to project</RouterLink>
  </div>

  <div v-else-if="data" class="narrow-page">
    <p class="eyebrow"><RouterLink :to="`/projects/${route.params.projectId}`">{{ data.project.name }}</RouterLink> / MINI-{{ data.ticket.id }}</p>
    <div class="ticket-detail-heading">
      <div>
        <span class="status-chip" :class="`status-${data.ticket.status}`">{{ data.ticket.status.replace("_", " ") }}</span>
        <h1>{{ data.ticket.title }}</h1>
      </div>
      <div class="detail-actions">
        <RouterLink class="button button-quiet" :to="`/projects/${route.params.projectId}/tickets/${route.params.ticketId}/edit`">Edit</RouterLink>
        <button class="button button-danger" type="button" @click="deleteTicket">Delete</button>
      </div>
    </div>

    <div class="detail-layout">
      <article class="detail-main">
        <p class="detail-description">{{ data.ticket.description || "No description yet." }}</p>
        <section class="comments">
          <div class="section-heading"><h2>Comments</h2><span>{{ data.comments.length }}</span></div>
          <div v-for="comment in data.comments" :key="comment.id" class="comment">
            <span class="avatar avatar-small">{{ comment.author?.initials || "?" }}</span>
            <div class="comment-content">
              <div class="comment-meta">
                <strong>{{ comment.author?.name || "Unknown user" }}</strong><span>MINI-{{ data.ticket.id }}</span>
                <div class="comment-actions"><button type="button" @click="startEditing(comment)">Edit</button><button type="button" @click="deleteComment(comment)">Delete</button></div>
              </div>
              <form v-if="editingId === comment.id" @submit.prevent="updateComment(comment)"><textarea v-model="editingBody" rows="3" required /><button class="button button-primary button-small" type="submit">Save</button></form>
              <p v-else>{{ comment.body }}</p>
            </div>
          </div>
          <form class="comment-form" @submit.prevent="addComment"><textarea v-model="commentBody" rows="3" placeholder="Leave a comment…" required /><button class="button button-primary" type="submit">Add comment</button></form>
        </section>
      </article>
      <aside class="detail-sidebar">
        <div><span class="sidebar-label">Assignee</span><p v-if="data.ticket.assignee" class="person"><span class="avatar avatar-small">{{ data.ticket.assignee.initials }}</span>{{ data.ticket.assignee.name }}</p><p v-else class="muted">Unassigned</p></div>
        <div><span class="sidebar-label">Reported by</span><p v-if="data.ticket.reporter" class="person"><span class="avatar avatar-small">{{ data.ticket.reporter.initials }}</span>{{ data.ticket.reporter.name }}</p><p v-else class="muted">Unknown</p></div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref, watch } from "vue"
import { RouterLink, useRoute, useRouter } from "vue-router"
import { api } from "../api"

const route = useRoute()
const router = useRouter()
const data = ref(null)
const loading = ref(true)
const commentBody = ref("")
const editingId = ref(null)
const editingBody = ref("")
const error = ref("")

async function load() {
  loading.value = true
  error.value = ""
  data.value = null
  try {
    data.value = await api.getTicket(route.params.projectId, route.params.ticketId)
  } catch (exception) {
    error.value = exception.message
  } finally {
    loading.value = false
  }
}

function startEditing(comment) {
  editingId.value = comment.id
  editingBody.value = comment.body
}

async function addComment() {
  if (!commentBody.value.trim()) return
  await api.addComment(route.params.projectId, route.params.ticketId, commentBody.value)
  commentBody.value = ""
  await load()
}

async function updateComment(comment) {
  await api.updateComment(route.params.projectId, route.params.ticketId, comment.id, editingBody.value)
  editingId.value = null
  await load()
}

async function deleteComment(comment) {
  await api.deleteComment(route.params.projectId, route.params.ticketId, comment.id)
  await load()
}

async function deleteTicket() {
  if (!window.confirm("Delete this ticket?")) return
  await api.deleteTicket(route.params.projectId, route.params.ticketId)
  await router.push(`/projects/${route.params.projectId}`)
}

watch(() => route.params.ticketId, load)
onMounted(load)
</script>

<style scoped>
.page-state { margin: 0 auto; max-width: 920px; padding: 36px 0; }
.error-message p { margin-bottom: 12px; }
</style>
