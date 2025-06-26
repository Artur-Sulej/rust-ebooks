# Rust eBooks Nightly

[![GitHub Pages Build Status](https://github.com/Artur-Sulej/rust-ebooks/actions/workflows/publish.yml/badge.svg)](https://github.com/Artur-Sulej/rust-ebooks/actions/workflows/publish.yml)

This project automatically builds and publishes the latest versions of top Rust books as eBooks – in EPUB, AZW3 and MOBI formats.

Built fresh from source. Updated daily. Ready for offline reading.

## Access the Books

Download the latest eBooks anytime from the project’s GitHub Pages site:

[https://artur-sulej.github.io/rust-ebooks](https://artur-sulej.github.io/rust-ebooks)

Source code is available on GitHub: [Artur-Sulej/rust-ebooks](https://github.com/Artur-Sulej/rust-ebooks)

## How It Works

A daily GitHub Actions workflow:

- clones each book’s repository
- builds the content with `mdBook`
- converts it to eBook formats using Calibre
- publishes the results to GitHub Pages

---

Enjoy Rust books on your favorite device!