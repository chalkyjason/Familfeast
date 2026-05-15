#!/usr/bin/env ruby

require "fileutils"

INPUT_PATH = File.join("docs", "APP_STORE_SUBMISSION.md")
DEFAULT_OUTPUT_DIR = File.join("fastlane", "metadata", "en-US")

FILE_MAP = {
  "description" => "description.txt",
  "keywords" => "keywords.txt",
  "promo_text" => "promotional_text.txt",
  "whats_new" => "release_notes.txt",
  "support_url" => "support_url.txt",
  "marketing_url" => "marketing_url.txt",
  "privacy_url" => "privacy_url.txt",
  "subtitle" => "subtitle.txt",
  "name" => "name.txt"
}.freeze

LOCALIZED_FIELDS = %w[
  description
  keywords
  promo_text
  whats_new
  support_url
  marketing_url
].freeze

APP_FIELDS = %w[
  name
  subtitle
].freeze

PRIVACY_FIELDS = %w[
  privacy_url
].freeze

def parse_fields(lines)
  fields = {}
  index = 0

  while index < lines.length
    line = lines[index]

    if (match = line.match(/^([a-z_]+):\s*\|\s*$/))
      key = match[1]
      index += 1
      block = []

      while index < lines.length
        current = lines[index]
        break if current.match?(/^[a-z_]+:/) || current.start_with?("## ", "### ", "- question:")

        if current.start_with?("  ")
          block << current.sub(/^  /, "")
        elsif current.strip.empty?
          block << ""
        else
          break
        end

        index += 1
      end

      fields[key] = block.join("\n").rstrip
      next
    end

    if (match = line.match(/^([a-z_]+):\s*(.*)$/))
      fields[match[1]] = match[2].strip
    end

    index += 1
  end

  fields
end

def extract_section(lines, heading_pattern, stop_patterns)
  start_index = lines.index { |line| line.match?(heading_pattern) }
  abort("Missing section matching #{heading_pattern.inspect} in #{INPUT_PATH}") unless start_index

  section_lines = []
  index = start_index + 1

  while index < lines.length
    current = lines[index]
    break if stop_patterns.any? { |pattern| current.match?(pattern) }

    section_lines << current
    index += 1
  end

  section_lines
end

abort("Missing submission doc at #{INPUT_PATH}") unless File.exist?(INPUT_PATH)

document_lines = File.readlines(INPUT_PATH, chomp: true)
app_fields = parse_fields(
  extract_section(document_lines, /^## App$/, [/^## /])
).slice(*APP_FIELDS)
localized_fields = parse_fields(
  extract_section(document_lines, /^### English \(en-US\)$/, [/^### /, /^## /])
).slice(*LOCALIZED_FIELDS)
privacy_fields = parse_fields(
  extract_section(document_lines, /^## Privacy$/, [/^## /])
).slice(*PRIVACY_FIELDS)
fields = app_fields.merge(localized_fields).merge(privacy_fields)
missing_keys = FILE_MAP.keys.reject { |key| fields[key] && !fields[key].empty? }

unless missing_keys.empty?
  abort("Missing required metadata fields: #{missing_keys.join(', ')}")
end

output_dir = ENV.fetch("FASTLANE_METADATA_OUTPUT_DIR", DEFAULT_OUTPUT_DIR)
FileUtils.mkdir_p(output_dir)

FILE_MAP.each do |field, file_name|
  output_path = File.join(output_dir, file_name)
  File.write(output_path, "#{fields.fetch(field).rstrip}\n")
end
