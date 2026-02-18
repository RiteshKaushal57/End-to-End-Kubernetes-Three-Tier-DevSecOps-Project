# ---------- Build Stage ----------
FROM node:16-alpine AS builder

WORKDIR /app

ENV CI=true

# Install dependencies first
COPY package*.json ./
RUN npm ci

# Copy rest of source
COPY . .

ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=/api/tasks

RUN npm run build


# ---------- Production Stage ----------
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]




# When we build the frontend image, the process first uses Node.js only as a build tool to install dependencies and run npm run build, which converts the React source code into plain static files such as HTML, CSS, and JavaScript inside the build/ directory. At this point, React, Node, npm, and all build tools have completed their job and are no longer needed. In the next step, a fresh, lightweight Nginx image is used, and only the generated build/ folder is copied into it. Nginx then serves these static files directly to users over HTTP while running in the foreground so the container stays alive. As a result, the final running container contains only Nginx and static website files, making it smaller, faster, more secure, and closer to real production behavior, while all development and build complexity is left behind in the discarded build stage.