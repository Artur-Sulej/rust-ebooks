# Rust eBooks Nightly

This project builds and publishes the latest versions of popular Rust books in convenient eBook formats (EPUB, AZW3, MOBI) for offline reading.  
New versions are generated every day.

## Access the Books

Download the latest eBooks anytime from the project’s GitHub Pages site:

[https://artur-sulej.github.io/rust-ebooks](https://artur-sulej.github.io/rust-ebooks)

## How It Works

A daily GitHub Actions workflow:

- clones each book’s repository
- builds the content with `mdBook`
- converts it to eBook formats using Calibre
- publishes the results to GitHub Pages

---

Enjoy Rust books on your favorite device!