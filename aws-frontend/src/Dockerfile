# frontend/Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /frontend

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 8091
EXPOSE 8091

# Start the frontend application
CMD ["npm", "run", "dev"]