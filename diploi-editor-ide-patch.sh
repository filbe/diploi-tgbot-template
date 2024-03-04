#!/bin/bash

# Default port if EDITOR_PORT is not set
default_port=12164
editor_port=${EDITOR_PORT:-$default_port}

# Function to update diploi-runonce.sh
update_diploi_runonce() {
    if grep -q "supervisorctl start" diploi-runonce.sh; then
        if ! grep -q "supervisorctl start code-server" diploi-runonce.sh; then
            # Add "supervisorctl start code-server" after the last "supervisorctl" command
            sed -i '/supervisorctl/!b;n;a supervisorctl start code-server' diploi-runonce.sh
        fi
    else
        if grep -q "progress \"Runonce done\";" diploi-runonce.sh; then
            # Add "supervisorctl start code-server" just before "progress \"Runonce done\";"
            sed -i '/progress "Runonce done";/i supervisorctl start code-server' diploi-runonce.sh
        else
            echo "Error: No line with 'supervisorctl start' or 'progress \"Runonce done\";' found in diploi-runonce.sh"
            exit 1
        fi
    fi
}

# Function to update supervisord.conf
update_supervisord_conf() {
    if ! grep -q "\[program:code-server\]" supervisord.conf; then
        # Add the specified section with dynamic port
        echo -e "\n[program:code-server]
directory=/app
command=code-server --app-name Diploi --disable-getting-started-override --disable-workspace-trust --disable-update-check --disable-telemetry --auth none --bind-addr 0.0.0.0:$editor_port /app
autostart=false
autorestart=true
stopasgroup=true
killasgroup=true
stdout_logfile=/var/log/code-server.log
stderr_logfile=/var/log/code-server.log" >> supervisord.conf
    fi
}

# Function to update templates/app-service.yaml
update_app_service_yaml() {
    if ! grep -q "name: editor" templates/app-service.yaml; then
        # Add the editor port entry
        sed -i '/ports:/a \    - port: '"$editor_port"'\n      name: editor' templates/app-service.yaml
    fi
}

# Function to find and update the correct app yaml file
update_app_yaml() {
    find templates -type f \( -iname "*app*.yaml" -o -iname "*app*.yml" \) | while read -r file; do
        if [[ $file == *"service"* ]]; then
            continue
        elif [[ $file == *"statefulset"* ]] || [[ $file == *"stateful-set"* ]] || [[ $file == *"deployment"* ]] || [[ $file == *"/app.yaml"* ]]; then
            # Check if our port is already in the file
            if ! grep -q "containerPort: $editor_port" "$file"; then
                # Find the line number of the last occurrence of "containerPort"
                last_port_line=$(awk '/containerPort:/ {line=NR} END{print line}' "$file")
                if [ -n "$last_port_line" ]; then
                    # Use awk to insert a new containerPort line after the last occurrence
                    awk -v port="$editor_port" -v line="$last_port_line" 'NR==line {print $0 "\n            - containerPort: " port; next}1' "$file" > tmpfile && mv tmpfile "$file"
                else
                    echo "No containerPort found in $file. Please check the file structure."
                fi
            fi
        fi
    done
}



# Function to update diploi-template.yaml
update_diploi_template_yaml() {
    if ! grep -q "editors:" diploi-template.yaml; then
        echo -e "editors:\n  - name: App\n    identifier: app\n    service: app\n    port: $editor_port\n    stages:\n      - development" >> diploi-template.yaml
    fi
}

# Execute the functions
update_diploi_runonce
update_supervisord_conf
update_app_service_yaml
update_app_yaml
update_diploi_template_yaml

echo "Updates complete."
