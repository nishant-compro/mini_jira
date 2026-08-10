import { createApp } from "vue"
import { createRouter, createWebHistory } from "vue-router"
import App from "./App.vue"
import ProjectsView from "./views/ProjectsView.vue"
import ProjectView from "./views/ProjectView.vue"
import TicketView from "./views/TicketView.vue"
import TicketFormView from "./views/TicketFormView.vue"
import "./style.css"

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", redirect: "/projects" },
    { path: "/projects", component: ProjectsView },
    { path: "/projects/:projectId", component: ProjectView },
    { path: "/projects/:projectId/tickets/new", component: TicketFormView },
    { path: "/projects/:projectId/tickets/:ticketId", component: TicketView },
    { path: "/projects/:projectId/tickets/:ticketId/edit", component: TicketFormView }
  ]
})

createApp(App).use(router).mount("#app")
