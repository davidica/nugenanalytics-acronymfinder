const state = {
    data: [],
    query: '',
    letter: '',
    category: ''
};

const $ = (id) => document.getElementById(id);

const elements = {
    search: $('q'),
    clear: $('clear'),
    count: $('count'),
    letters: $('letters'),
    category: $('category'),
    results: $('results'),
    empty: $('empty'),
    theme: $('theme')
};

function escapeHtml(value) {
    return String(value).replace(
        /[&<>"']/g,
        (character) => ({
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;'
        })[character]
    );
}

function getFilteredItems() {
    const query = state.query
        .toLowerCase()
        .trim();

    return state.data
        .filter((item) => {
            return (
                !state.letter ||
                item.acronym
                    .toUpperCase()
                    .startsWith(state.letter)
            );
        })
        .filter((item) => {
            return (
                !state.category ||
                item.category === state.category
            );
        })
        .filter((item) => {
            if (!query) {
                return true;
            }

            return [
                item.acronym,
                item.term,
                item.category
            ].some((value) => {
                return value
                    .toLowerCase()
                    .includes(query);
            });
        })
        .sort((left, right) => {
            return left.acronym.localeCompare(
                right.acronym
            );
        });
}

 function renderResults() {
    const items = getFilteredItems();

    elements.count.textContent =
        items.length;

    elements.empty.hidden =
        items.length > 0;

    elements.results.innerHTML =
        items.map((item) => {

            const description =
                item.description
                    ? `
                        <p class="description">
                            ${escapeHtml(item.description)}
                        </p>
                    `
                    : '';

            const source =
                item.source
                    ? `
                        <div class="source">
                            <strong>Source:</strong>
                            ${escapeHtml(item.source)}
                        </div>
                    `
                    : '';

            const sourceType =
                item.sourceType
                    ? `
                        <span class="source-type">
                            ${escapeHtml(item.sourceType)}
                        </span>
                    `
                    : '';

            const verified =
                item.verified === true
                    ? `
                        <span class="verified">
                            ✓ Verified
                        </span>
                    `
                    : '';

            const reviewMessage =
                item.needsReview
                    ? `
                        <div class="review">
                            Source text needs review before publication.
                        </div>
                    `
                    : '';

            return `
                <article class="card">

                    <div class="top">

                        <div class="acro">
                            ${escapeHtml(item.acronym)}
                        </div>

                        <div class="card-content">

                            <div class="term">
                                ${escapeHtml(item.term)}
                            </div>

                            <span class="tag">
                                ${escapeHtml(item.category)}
                            </span>

                            ${description}

                            ${
                                source ||
                                sourceType ||
                                verified
                                    ? `
                                        <div class="source-block">
                                            ${source}

                                            <div class="source-meta">
                                                ${sourceType}
                                                ${verified}
                                            </div>
                                        </div>
                                    `
                                    : ''
                            }

                            ${reviewMessage}

                        </div>

                    </div>

                </article>
            `;
        })
        .join('');
}

function buildLetterFilters() {
    const letters = [
        'ALL',
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    ];

    letters.forEach((letter) => {

        const button =
            document.createElement('button');

        button.type = 'button';

        button.className =
            'letter';

        button.textContent =
            letter === 'ALL'
                ? 'All'
                : letter;

        if (letter === 'ALL') {
            button.classList.add(
                'active'
            );
        }

        button.addEventListener(
            'click',
            () => {

                state.letter =
                    letter === 'ALL'
                        ? ''
                        : letter;

                document
                    .querySelectorAll('.letter')
                    .forEach((item) => {
                        item.classList.remove(
                            'active'
                        );
                    });

                button.classList.add(
                    'active'
                );

                renderResults();
            }
        );

        elements.letters.appendChild(
            button
        );
    });
}

function buildCategoryFilter() {
    const categories = [
        ...new Set(
            state.data.map(
                (item) => item.category
            )
        )
    ].sort();

    categories.forEach((category) => {

        const option =
            document.createElement('option');

        option.value =
            category;

        option.textContent =
            category;

        elements.category.appendChild(
            option
        );
    });
}

function initializeTheme() {
    const savedTheme =
        localStorage.getItem(
            'theme'
        );

    if (savedTheme) {
        document.documentElement.dataset.theme =
            savedTheme;
    }

    elements.theme.textContent =
        document.documentElement.dataset.theme ===
        'dark'
            ? '☀'
            : '☾';
}

function toggleTheme() {
    const currentTheme =
        document.documentElement.dataset.theme;

    const newTheme =
        currentTheme === 'dark'
            ? 'light'
            : 'dark';

    document.documentElement.dataset.theme =
        newTheme;

    localStorage.setItem(
        'theme',
        newTheme
    );

    elements.theme.textContent =
        newTheme === 'dark'
            ? '☀'
            : '☾';
}

elements.search.addEventListener(
    'input',
    (event) => {

        state.query =
            event.target.value;

        renderResults();
    }
);

elements.clear.addEventListener(
    'click',
    () => {

        elements.search.value =
            '';

        state.query =
            '';

        renderResults();

        elements.search.focus();
    }
);

elements.category.addEventListener(
    'change',
    (event) => {

        state.category =
            event.target.value;

        renderResults();
    }
);

elements.theme.addEventListener(
    'click',
    toggleTheme
);

async function initializeApplication() {
    initializeTheme();

    buildLetterFilters();

    try {

        const response =
            await fetch(
                'acronyms.json'
            );

        if (!response.ok) {
            throw new Error(
                `HTTP ${response.status}`
            );
        }

        state.data =
            await response.json();

        buildCategoryFilter();

        renderResults();
    }
    catch (error) {

        elements.empty.hidden =
            false;

        elements.empty.textContent =
            (
                'Unable to load acronym data. ' +
                'Run this utility through a local or hosted web server.'
            );

        console.error(
            'Acronym data load failed:',
            error
        );
    }
}

initializeApplication();