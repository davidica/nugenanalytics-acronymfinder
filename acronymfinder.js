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
 
const sourceUrls = {

    /* ============================================================
       CMMC / eCFR
       ============================================================ */

    "32 CFR Part 170":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170",

    "32 CFR 170.4 / 170.10":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170",

    "32 CFR 170.12":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170/section-170.12",

    "32 CFR 170.14(c)(1)":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170/section-170.14",

    "32 CFR 170.24":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170/section-170.24",

    "32 CFR Part 170 / DFARS":
        "https://www.ecfr.gov/current/title-32/subtitle-A/chapter-I/subchapter-D/part-170",

    "CMMC Program":
        "https://dodcio.defense.gov/CMMC/Resources-Documentation/",

    "CMMC Program terminology":
        "https://dodcio.defense.gov/CMMC/Resources-Documentation/",

    "CMMC Program / NIST":
        "https://dodcio.defense.gov/CMMC/Resources-Documentation/",


    /* ============================================================
       CUI / NARA
       ============================================================ */

    "32 CFR 2002.4(h) / NIST":
        "https://csrc.nist.gov/glossary/term/controlled_unclassified_information",

    "NARA CUI Program":
        "https://www.archives.gov/cui",


    /* ============================================================
       NIST
       ============================================================ */

    "NIST":
        "https://www.nist.gov/",

    "NIST CSRC Glossary":
        "https://csrc.nist.gov/glossary",

    "NIST SP 800-171 / CMMC":
        "https://csrc.nist.gov/pubs/sp/800/171/r2/upd1/final",

    "NIST SP 800-171 Rev. 2 / CMMC":
        "https://csrc.nist.gov/pubs/sp/800/171/r2/upd1/final",

    "NIST SP 800-171 Rev. 3 / NIST CSRC Glossary":
        "https://csrc.nist.gov/pubs/sp/800/171/r3/final",

    "NIST SP 800-39 / NIST CSRC Glossary":
        "https://csrc.nist.gov/pubs/sp/800/39/final",

    "NIST SP 800-82":
        "https://csrc.nist.gov/pubs/sp/800/82/r3/final",

    "NIST SP 800-82 Rev. 3 / NIST CSRC Glossary":
        "https://csrc.nist.gov/pubs/sp/800/82/r3/final",

    "NIST / Industrial Cybersecurity terminology":
        "https://csrc.nist.gov/pubs/sp/800/82/r3/final",

    "NIST CSRC Glossary / NIST SP 800-92":
        "https://csrc.nist.gov/glossary",

    "FedRAMP / NIST":
        "https://www.fedramp.gov/",


    /* ============================================================
       FAR / Acquisition
       ============================================================ */

    "FAR":
        "https://www.acquisition.gov/far",

    "FAR 1.101":
        "https://www.acquisition.gov/far/1.101",

    "FAR 4.1901 / CMMC":
        "https://www.acquisition.gov/far/4.1901",

    "FAR 52.204-16":
        "https://www.acquisition.gov/far/52.204-16",

    "FAR / SAM.gov":
        "https://sam.gov/",

    "Federal Acquisition terminology":
        "https://www.acquisition.gov/far",


    /* ============================================================
       DFARS
       ============================================================ */

    "DFARS":
        "https://www.acquisition.gov/dfars",


    /* ============================================================
       FedRAMP
       ============================================================ */

    "FedRAMP":
        "https://www.fedramp.gov/",


    /* ============================================================
       Department of Defense / DCMA
       ============================================================ */

    "Department of Defense":
        "https://www.defense.gov/",

    "U.S. Department of Defense":
        "https://www.defense.gov/",

    "Defense Contract Management Agency":
        "https://www.dcma.mil/",

    "DCMA DIBCAC":
        "https://www.dcma.mil/DIBCAC/",

    "Department of Defense PIEE":
        "https://piee.eb.mil/",


    /* ============================================================
       Federal Systems / Government
       ============================================================ */

    "Code of Federal Regulations":
        "https://www.ecfr.gov/",

    "Federal IT terminology":
        "https://www.cio.gov/",

    "Federal Information Technology terminology":
        "https://www.cio.gov/",

    "Federal statistical and acquisition terminology":
        "https://www.census.gov/naics/",

    "Paperwork Reduction Act":
        "https://www.govinfo.gov/content/pkg/USCODE-2023-title44/html/USCODE-2023-title44-chap35.htm",


    /* ============================================================
       SAM
       ============================================================ */

    "SAM.gov":
        "https://sam.gov/",


    /* ============================================================
       Standards Organizations
       ============================================================ */

    "IEC":
        "https://www.iec.ch/",

    "ISO / IEC":
        "https://www.iso.org/",


    /* ============================================================
       General Cybersecurity
       ============================================================ */

    "Cybersecurity industry terminology":
        "https://csrc.nist.gov/glossary"
};

 
 
function getSourceUrl(item) {
    if (item.sourceUrl) {
        return item.sourceUrl;
    }

    return sourceUrls[item.source] || null;
}

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
             
            const sourceUrl =
                getSourceUrl(item);

             const source =
    item.source
        ? `
            <div class="source">
                <strong>Source:</strong>
                ${
                    sourceUrl
                        ? `
                            <a
                                href="${escapeHtml(sourceUrl)}"
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                ${escapeHtml(item.source)}
                            </a>
                        `
                        : escapeHtml(item.source)
                }
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

let searchAnalyticsTimer;

elements.search.addEventListener(
    'input',
    (event) => {

        state.query =
            event.target.value;

        renderResults();

        clearTimeout(searchAnalyticsTimer);

        searchAnalyticsTimer = setTimeout(
            () => {

                const searchTerm =
                    getTelemetrySearchTerm(
                        state.query
                    );

                if (searchTerm) {
                    trackEvent(
                        'search',
                        {
                            search_term:
                                searchTerm
                        }
                    );
                }
            },
            800
        );
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