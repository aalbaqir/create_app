require 'net/http' # Load the HTTP module
require 'uri'
require 'json'
require 'fileutils'

class MediaController < ApplicationController
  # POST /upload
  def upload
    if params[:file].present?
      begin
        # Save the uploaded file in 'public/uploads'
        uploaded_file = params[:file]
        file_path = save_file(uploaded_file)

        # Check file permissions before processing
        check_file_permissions(file_path)

        # Send the file to the Python Flask service and get the caption
        caption = send_file_to_python_service(file_path)

        # Get the relative URL to the file for display in the frontend
        image_url = url_for_file(file_path)

        # Render the generated caption and the image URL as a JSON response
        render json: { caption: caption, image_url: image_url }, status: :ok
      rescue => e
        Rails.logger.error "Error processing upload: #{e.message}"
        render json: { error: 'Failed to process upload' }, status: :internal_server_error
      end
    else
      render json: { error: 'No file uploaded' }, status: :unprocessable_entity
    end
  end

  # POST /generate_new_caption
  def generate_new_caption
    if params[:image_url].present?
      begin
        Rails.logger.info "Received image URL: #{params[:image_url]}"

        # Construct the file path from the image URL
        file_path = Rails.root.join('public', 'uploads', params[:image_url].sub("/uploads/", ""))
        Rails.logger.info "Constructed file path: #{file_path}"

        # Check if the file exists
        unless File.exist?(file_path)
          raise "File not found: #{file_path}"
        end

        # Send the file to the Python Flask service and get the new caption
        caption = send_file_to_python_service(file_path)

        # Render the generated caption as a JSON response
        render json: { caption: caption }, status: :ok
      rescue => e
        Rails.logger.error "Error processing request: #{e.message}"
        render json: { error: 'Failed to generate new caption' }, status: :internal_server_error
      end
    else
      Rails.logger.error "Image URL not provided"
      render json: { error: 'Image URL not provided' }, status: :unprocessable_entity
    end
  end

  private

  # Save the uploaded file permanently in 'public/uploads'
  def save_file(uploaded_file)
    uploads_path = Rails.root.join('public', 'uploads')

    # Ensure the uploads directory exists
    FileUtils.mkdir_p(uploads_path) unless Dir.exist?(uploads_path)

    # Sanitize the file name (remove special characters)
    sanitized_file_name = uploaded_file.original_filename.gsub(/[^0-9A-Za-z.\-]/, '_')
    file_path = uploads_path.join(sanitized_file_name)

    # Save the file using IO.binwrite
    begin
      IO.binwrite(file_path, uploaded_file.read)
      Rails.logger.info "File successfully saved at: #{file_path}"
    rescue => e
      Rails.logger.error "Error saving file: #{e.message}"
      raise e
    end

    # Return the file path for further processing
    file_path
  end

  # Check file readability and writability after saving
  def check_file_permissions(file_path)
    unless File.readable?(file_path)
      raise "File is not readable at: #{file_path}"
    end

    unless File.writable?(file_path)
      raise "File is not writable at: #{file_path}"
    end

    Rails.logger.info "File is readable and writable at: #{file_path}"
  end

  # Send the file to the Python Flask service for caption generation
  def send_file_to_python_service(file_path)
    Rails.logger.info "Preparing to send file to Python service: #{file_path}"

    begin
      uri = URI.parse('http://localhost:5000/generate_caption')
      request = Net::HTTP::Post.new(uri)

      # Open the file in binary mode, ensuring it is closed after use
      File.open(file_path, 'rb') do |file|
        form_data = [['file', file]]
        request.set_form form_data, 'multipart/form-data'

        # Send request to Flask service
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end

        # Handle the response
        if response.is_a?(Net::HTTPSuccess)
          Rails.logger.info "Caption successfully generated from Python service"
          return JSON.parse(response.body)['caption']
        else
          raise "Failed to generate caption: #{response.message}"
        end
      end
    rescue => e
      Rails.logger.error "Error processing file in Python service: #{e.message}"
      raise e
    end
  end

  # Generate a public URL for the uploaded file
  def url_for_file(file_path)
    # Extract the file name and construct a public URL for the file
    file_name = File.basename(file_path)
    "/uploads/#{file_name}"
  end
end
