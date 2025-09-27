# Use Node.js 16 LTS as the base image
FROM node:16

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the application code
COPY . .

# Expose the port that app runs on
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
