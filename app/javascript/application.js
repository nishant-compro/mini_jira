// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createApp, computed, ref } from "vue"

const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

async function request(url, method = "GET", params = {}) {
	const options = {
		method,
		headers: { Accept: "application/json", "X-CSRF-Token": csrfToken }
	}

	if (method !== "GET") {
		options.headers["Content-Type"] = "application/json"
		options.body = JSON.stringify(params)
	}

	const response = await fetch(url, options)
	const body = await response.json().catch(() => ({}))
	if (!response.ok) throw body
	return body
}

function avatar(user, accent = false) {
	return user ? user.initials : "?"
}

function statusLabel(status) {
	return { todo: "To do", in_progress: "In progress", done: "Done" }[status] || status
}

const ProjectIndex = {
	props: ["data"],
	setup(props) {
		const newUser = ref({ name: "", email: "" })
		const selectedUser = ref(props.data.current_user?.id || props.data.users[0]?.id || "")
		const userError = ref(props.data.user_errors?.join(", ") || "")

		async function switchUser() {
			await request("/users/switch", "POST", { user_id: selectedUser.value })
			props.data.current_user = props.data.users.find(user => user.id === Number(selectedUser.value))
		}

		async function addUser() {
			userError.value = ""
			try {
				await request("/users", "POST", { user: newUser.value })
				window.location.reload()
			} catch (error) {
				userError.value = error.errors?.join(", ") || "Unable to create user"
			}
		}

		return { newUser, selectedUser, userError, switchUser, addUser, avatar }
	},
	template: `
		<main class="page">
			<header class="page-header">
				<h1 class="page-title">Projects</h1>
				<div class="page-header__actions">
					  <a data-turbo="false" href="/projects/new" class="btn">＋ New project</a>
					<details class="user-menu">
						<summary class="user-menu__trigger" aria-label="Open user menu">
							<span class="avatar avatar--accent" style="width:22px;height:22px;font-size:10px">{{ avatar(data.current_user) }}</span> ◉
						</summary>
						<div class="user-menu__panel">
							<div class="user-menu__label">Current user</div>
							<div v-if="data.current_user" class="user-menu__current">
								<span class="avatar avatar--accent" style="width:28px;height:28px;font-size:11px">{{ avatar(data.current_user) }}</span>
								<div><div class="user-menu__name">{{ data.current_user.name }}</div><div class="user-menu__email">{{ data.current_user.email }}</div></div>
							</div>
							<div v-else class="user-menu__empty">No users yet</div>
							<form v-if="data.users.length" class="switch-user-form" @submit.prevent="switchUser">
								<div class="user-menu__label">Switch user</div>
								<select id="user_id" name="user_id" v-model="selectedUser" class="form-input"><option v-for="user in data.users" :key="user.id" :value="user.id">{{ user.name }}</option></select>
								<button class="btn">Switch</button>
							</form>
							<details class="add-user"><summary class="add-user__summary">＋ Add user</summary>
								<form class="user-form" @submit.prevent="addUser"><div v-if="userError" class="form-errors">{{ userError }}</div><input v-model="newUser.name" class="form-input" placeholder="Name"><input v-model="newUser.email" class="form-input" type="email" placeholder="Email"><button class="btn">Create user</button></form>
							</details>
						</div>
					</details>
				</div>
			</header>
			<div class="stack"><a data-turbo="false" v-for="project in data.projects" :key="project.id" :href="project.url" class="row-card project-row"><span class="icon-tile">▦</span><div class="project-row__info"><div class="project-row__name">{{ project.name }}</div><div class="project-row__meta">{{ project.ticket_count }} ticket{{ project.ticket_count === 1 ? '' : 's' }} · {{ project.open_tickets_count }} open</div></div></a></div>
		</main>`
}

const ProjectBoard = {
	props: ["data"],
	setup(props) {
		const columns = computed(() => ["todo", "in_progress", "done"].map(status => ({ status, label: props.data.status_labels[status], tickets: props.data.tickets.filter(ticket => ticket.status === status) })))
		return { columns, avatar }
	},
	template: `<main class="page"><header class="page-header page-header--stacked"><div><a data-turbo="false" href="/projects" class="back-link">← Projects</a><h1 class="page-title">{{ data.project.name }}</h1></div><a data-turbo="false" :href="'/projects/' + data.project.id + '/tickets/new'" class="btn">＋ New ticket</a></header><div class="board"><section v-for="column in columns" :key="column.status" class="board-column"><div class="board-column__header">{{ column.label }} · {{ column.tickets.length }}</div><div class="stack stack--tight"><a data-turbo="false" v-for="(ticket, index) in column.tickets" :key="ticket.id" :href="ticket.url" class="ticket-card" :class="{ 'ticket-card--selected': column.status === 'in_progress' && index === 0, 'ticket-card--done': column.status === 'done' }"><div class="ticket-card__title">{{ ticket.title }}</div><div class="ticket-card__footer"><span class="badge" :class="'badge--status-' + ticket.status">{{ column.label }}</span><span class="avatar" style="width:20px;height:20px;font-size:10px">{{ avatar(ticket.assignee) }}</span></div></a></div></section></div></main>`
}

const ProjectForm = {
	props: ["data"],
	setup(props) {
		const project = ref({ ...props.data.project })
		const errors = ref(props.data.errors || [])
		async function save() {
			try { const result = await request("/projects", "POST", { project: project.value }); window.location.href = result.redirect_url }
			catch (error) { errors.value = error.errors || ["Unable to create project"] }
		}
		return { project, errors, save }
	},
	template: `<main class="page page--narrow"><header class="page-header"><h1 class="page-title">New Project</h1></header><div class="content-card"><form class="form" @submit.prevent="save"><div v-if="errors.length" class="form-errors"><div v-for="error in errors">{{ error }}</div></div><div class="form-field"><label class="form-label" for="project_name">Name</label><input id="project_name" name="project[name]" v-model="project.name" class="form-input" placeholder="Project name" autofocus></div><div class="form-field"><label class="form-label" for="project_description">Description</label><textarea id="project_description" name="project[description]" v-model="project.description" class="form-input form-textarea" rows="4" placeholder="Optional description"></textarea></div><div class="form-actions"><a data-turbo="false" href="/projects" class="btn btn--secondary">Cancel</a><button class="btn">Create project</button></div></form></div></main>`
}

const TicketForm = {
	props: ["data", "editing"],
	setup(props) {
		const ticket = ref({ ...props.data.ticket })
		const errors = ref(props.data.errors || [])
		async function save() {
			const url = props.editing ? `/projects/${props.data.project.id}/tickets/${ticket.value.id}` : `/projects/${props.data.project.id}/tickets`
			try { const result = await request(url, props.editing ? "PATCH" : "POST", { ticket: ticket.value }); window.location.href = result.redirect_url }
			catch (error) { errors.value = error.errors || ["Unable to save ticket"] }
		}
		return { ticket, errors, save }
	},
	template: `<main class="page page--narrow"><header class="page-header"><div><a data-turbo="false" :href="editing ? '/projects/' + data.project.id + '/tickets/' + ticket.id : '/projects/' + data.project.id" class="back-link">← {{ data.project.name }}</a><h1 class="page-title">{{ editing ? 'Edit Ticket' : 'New Ticket' }}</h1></div></header><div class="content-card"><form class="form" @submit.prevent="save"><div v-if="errors.length" class="form-errors"><div class="form-error__title">Please fix the following:</div><div v-for="error in errors">{{ error }}</div></div><div class="form-field"><label class="form-label" for="ticket_title">Title</label><input id="ticket_title" name="ticket[title]" v-model="ticket.title" class="form-input" placeholder="Ticket title" autofocus></div><div class="form-field"><label class="form-label" for="ticket_description">Description</label><textarea id="ticket_description" name="ticket[description]" v-model="ticket.description" class="form-input form-textarea" rows="5" placeholder="Describe the work"></textarea></div><div class="form-field"><label class="form-label" for="ticket_status">Status</label><select id="ticket_status" name="ticket[status]" v-model="ticket.status" class="form-input"><option v-for="status in data.statuses" :value="status.value">{{ status.label }}</option></select></div><div class="form-field"><label class="form-label" for="ticket_assignee_id">Assigned to</label><select id="ticket_assignee_id" name="ticket[assignee_id]" v-model="ticket.assignee_id" class="form-input"><option :value="null">Unassigned</option><option v-for="user in data.users" :value="user.id">{{ user.name }}</option></select></div><div class="form-actions"><a data-turbo="false" :href="editing ? '/projects/' + data.project.id + '/tickets/' + ticket.id : '/projects/' + data.project.id" class="btn btn--secondary">Cancel</a><button class="btn">{{ editing ? 'Save changes' : 'Create ticket' }}</button></div></form></div></main>`
}

const TicketDetail = {
	props: ["data"],
	setup(props) {
		const comments = ref([...props.data.comments])
		const newComment = ref("")
		const error = ref(props.data.comment_errors?.join(", ") || "")
		comments.value = comments.value.map(comment => ({ ...comment, draft: comment.body }))
		async function addComment() {
			try { const result = await request(`/projects/${props.data.project.id}/tickets/${props.data.ticket.id}/comments`, "POST", { comment: { body: newComment.value } }); comments.value.push(result.comment); newComment.value = "" }
			catch (failure) { error.value = failure.errors?.join(", ") || "Unable to add comment" }
		}
		async function deleteComment(comment) { await request(`/projects/${props.data.project.id}/tickets/${props.data.ticket.id}/comments/${comment.id}`, "DELETE"); comments.value = comments.value.filter(item => item.id !== comment.id) }
		async function updateComment(comment, event) { const result = await request(`/projects/${props.data.project.id}/tickets/${props.data.ticket.id}/comments/${comment.id}`, "PATCH", { comment: { body: comment.draft } }); comment.body = result.comment.body; event.target.closest("details").open = false }
		async function deleteTicket() { if (window.confirm("Delete this ticket?")) { const result = await request(props.data.ticket.url, "DELETE"); window.location.href = result.redirect_url } }
		return { comments, newComment, error, addComment, deleteComment, updateComment, deleteTicket, avatar, statusLabel }
	},
	template: `<main class="page page--narrow"><a data-turbo="false" :href="'/projects/' + data.project.id" class="back-link">← {{ data.project.name }}</a><div class="content-card"><div class="ticket-detail__header"><h1 class="ticket-detail__title">{{ data.ticket.title }}</h1><div class="ticket-detail__actions"><span class="badge" :class="'badge--status-' + data.ticket.status">{{ statusLabel(data.ticket.status) }}</span><a data-turbo="false" :href="data.ticket.edit_url" class="btn btn--small">Edit</a><button @click="deleteTicket" class="btn btn--small btn--danger">Delete</button></div></div><div class="ticket-detail__meta"><span class="meta-item">◎ Reported by {{ data.ticket.reporter?.name || 'Unknown' }}</span><span class="meta-item">◎ Assigned to {{ data.ticket.assignee?.name || 'Unassigned' }}</span></div><hr class="divider"><p class="ticket-detail__description">{{ data.ticket.description }}</p><hr class="divider"><div class="comments-label">Comments · {{ comments.length }}</div><div class="stack stack--comments"><div v-for="comment in comments" :key="comment.id" class="comment"><span class="avatar" style="width:22px;height:22px;font-size:10px">{{ avatar(comment.author) }}</span><div class="comment__body"><div class="comment__author">{{ comment.author?.name || 'Unknown' }}</div><div class="comment__text">{{ comment.body }}</div><div class="comment__actions"><details class="comment-edit"><summary class="comment-action">Edit</summary><form class="comment-edit__form" @submit.prevent="updateComment(comment, $event)"><input name="comment[body]" v-model="comment.draft" class="form-input"><button class="btn btn--small">Save</button></form></details><button class="comment-action" @click="deleteComment(comment)">Delete</button></div></div></div></div><form class="comment-form" @submit.prevent="addComment"><div v-if="error" class="form-errors">{{ error }}</div><input v-model="newComment" class="comment-input" placeholder="Add a comment..."><div class="comment-form__footer"><button class="btn">Add comment</button></div></form></div></main>`
}

function mountVue() {
	const mount = document.getElementById("vue-app")
	if (!mount || mount.dataset.vueMounted) return

	mount.dataset.vueMounted = "true"
	const page = mount.dataset.page
	const data = JSON.parse(mount.dataset.props)
	createApp({
		components: { ProjectIndex, ProjectBoard, ProjectForm, TicketForm, TicketDetail },
		template: `<project-index v-if="page === 'projects'" :data="data" /><project-board v-else-if="page === 'project'" :data="data" /><project-form v-else-if="page === 'new-project'" :data="data" /><ticket-form v-else-if="page === 'new-ticket'" :data="data" /><ticket-form v-else-if="page === 'edit-ticket'" :data="data" editing /><ticket-detail v-else-if="page === 'ticket'" :data="data" />`,
		setup() { return { page, data } }
	}).mount(mount)
}

mountVue()
document.addEventListener("turbo:load", mountVue)
