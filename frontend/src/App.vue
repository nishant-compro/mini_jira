<template>
  <div class="app-shell">
    <header class="topbar">
      <RouterLink class="brand" to="/projects"><span class="brand-mark">M</span><span>Mini Jira</span></RouterLink>
      <div v-if="loaded" class="topbar-actions">
        <div ref="userSwitcher" class="user-switcher">
          <span class="avatar">{{ initials }}</span>
          <button class="user-switcher-copy" type="button" :aria-expanded="showUserMenu" aria-haspopup="menu" @click="showUserMenu = !showUserMenu"><span class="user-switcher-label">Signed in as</span><span class="user-switcher-name">{{ currentUser?.name || "Choose user" }}</span></button>
          <div v-if="showUserMenu" class="user-menu" role="menu">
            <p class="user-menu-title">Switch user</p>
            <button v-for="user in users" :key="user.id" class="user-menu-item" :class="{ 'is-active': user.id === currentUser?.id }" type="button" role="menuitem" @click="switchUser(user.id)"><span class="avatar avatar-small">{{ user.initials }}</span><span>{{ user.name }}</span><span v-if="user.id === currentUser?.id" class="user-menu-check">✓</span></button>
          </div>
        </div>
        <button class="button button-quiet" type="button" @click="showUserForm = !showUserForm">New user</button>
      </div>
    </header>

    <section v-if="showUserForm" class="quick-form user-form">
      <form @submit.prevent="createUser"><div class="form-heading"><div><p class="eyebrow">Workspace</p><h2>Add a teammate</h2></div><button class="icon-button" type="button" aria-label="Close" @click="showUserForm = false">×</button></div><p v-if="userError" class="error-message" role="alert">{{ userError }}</p><div class="form-grid"><label>Name<input v-model="userForm.name" required /></label><label>Email<input v-model="userForm.email" type="email" required /></label></div><button class="button button-primary" type="submit">Create user</button></form>
    </section>

    <main class="page-wrap"><RouterView :projects="projects" :users="users" @project-created="handleProjectCreated" /></main>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from "vue"
import { RouterLink, RouterView, useRouter } from "vue-router"
import { api } from "./api"

const router = useRouter()
const projects = ref([])
const users = ref([])
const currentUser = ref(null)
const userForm = ref({ name: "", email: "" })
const userError = ref("")
const loaded = ref(false)
const showUserForm = ref(false)
const showUserMenu = ref(false)
const userSwitcher = ref(null)
const initials = computed(() => currentUser.value?.initials || "?")

async function loadShell() {
  try {
    const data = await api.getProjects()
    projects.value = data.projects
    users.value = data.users
    currentUser.value = data.current_user
  } finally { loaded.value = true }
}
async function handleProjectCreated(result) {
  await router.push(`/projects/${result.redirect_url.split("/").pop()}`)
  await loadShell()
}
async function createUser() {
  userError.value = ""
  try {
    await api.createUser(userForm.value)
    userForm.value = { name: "", email: "" }
    showUserForm.value = false
    await loadShell()
  } catch (error) { userError.value = error.message }
}
async function switchUser(userId) {
  await api.switchUser(userId)
  currentUser.value = users.value.find((user) => user.id === userId)
  showUserMenu.value = false
}
function closeUserMenu(event) {
  if (!userSwitcher.value?.contains(event.target)) showUserMenu.value = false
}

loadShell()
onMounted(() => document.addEventListener("click", closeUserMenu))
onBeforeUnmount(() => document.removeEventListener("click", closeUserMenu))
</script>

<style scoped>
.user-form { margin: 0 auto; max-width: 1180px; }
</style>
