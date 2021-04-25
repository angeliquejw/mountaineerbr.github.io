/**
 *
 * @param {string} event
 * @return { (element: HTMLElement|Window) => (callback: Function) => void }
 */
const fromEvent = (event) => (element) => (callback) => {
    return element.addEventListener(event, callback);
};

const fromEventArray = (event) => (elements) => (callback) => {
    return elements.forEach((element) => {
        element.addEventListener(event, callback);
    });
};

const fromClick = fromEvent('click');
const fromClickArray = fromEventArray('click');

const fromScroll = fromEvent('scroll');

/**
 *
 * @param {string} selector
 * @returns {HTMLElement|null}
 */
const select = (selector) => document.querySelector(selector);

/**
 *
 * @param {string} selector
 * @returns {NodeListOf<HTMLElement>}
 */
const selectAll = (selector) => document.querySelectorAll(selector);

const navbar = select('.navbar');
const menu = select('.menu[aria-expanded]');
const hamburger = select('.hamburger');
const internalLinks = selectAll('.menu .link[href^="#"][data-internal]');

const fromScrollInWindow = fromScroll(window);
const fromClickInHamburger = fromClick(hamburger);
const fromClickInInternalLinks = fromClickArray(internalLinks);

const toggleNavbar = () => {
    if (window.scrollY > 100) {
        navbar.classList.add('is-active');
    } else {
        navbar.classList.remove('is-active');
    }
};

const toggleHamburger = () => {
    const isMenuActive = menu.getAttribute('aria-expanded') === 'true';
    hamburger.classList.toggle('is-active');
    menu.setAttribute('aria-expanded', isMenuActive ? 'false' : 'true');
};

const smoothScroll = (event) => {
    event.preventDefault();
    toggleHamburger();

    const linkTarget = select(event.target.hash);
    linkTarget.scrollIntoView({
        behavior: 'smooth',
        block: 'start',
    });
};

fromScrollInWindow(toggleNavbar);
fromClickInHamburger(toggleHamburger);
fromClickInInternalLinks(smoothScroll);
