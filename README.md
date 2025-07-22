# Rust eBooks Nightly

[![GitHub Pages Build Status](https://github.com/Artur-Sulej/rust-ebooks/actions/workflows/publish.yml/badge.svg)](https://github.com/Artur-Sulej/rust-ebooks/actions/workflows/publish.yml)

This project automatically builds and publishes the latest versions of top Rust books as eBooks – in EPUB, AZW3, MOBI and PDF formats.

Built fresh from source. Updated daily. Ready for offline reading.

Enjoy Rust books on your favorite device!

## Access the Books

Download the latest eBooks:  
[https://artur-sulej.github.io/rust-ebooks](https://artur-sulej.github.io/rust-ebooks/)

Browse the source code:  
[https://github.com/Artur-Sulej/rust-ebooks](https://github.com/Artur-Sulej/rust-ebooks)

## How It Works

Every day, a [GitHub Actions workflow](https://github.com/Artur-Sulej/rust-ebooks/actions/workflows/publish.yml):

- Clones each book’s repository
- Builds the content with `mdBook`
- Converts it to eBook and PDF formats using Calibre
- Publishes the results to [GitHub Pages](https://artur-sulej.github.io/rust-ebooks/)

If a book fails to build, it's skipped and a GitHub issue is created automatically. Other books continue building as usual.

## Author

Hi, I'm Artur! Feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/artursulej/) if you'd like to chat about Rust, open source or anything tech-related!
