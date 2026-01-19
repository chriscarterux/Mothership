// Step Data
const stepData = {
    assimilate: {
        icon: '🛸',
        title: 'ASSIMILATE',
        agent: 'Scanner Agent',
        function: 'Scans and absorbs project configuration, dependencies, and codebase structure. The Scanner creates a complete mental map of the project ecosystem, identifying patterns, conventions, and integration points.',
        output: `> SCANNING PROJECT STRUCTURE...
> Found: package.json, tsconfig.json
> Analyzing 147 source files...
> Dependency graph: 23 packages
> Convention: ESM + TypeScript
> Framework: React 18.2.0
> ASSIMILATION COMPLETE ✓`,
        time: '02:30'
    },
    plan: {
        icon: '🔮',
        title: 'PLAN',
        agent: 'Oracle Agent',
        function: 'The Oracle receives the task and generates a strategic execution plan. It breaks down complex requirements into atomic stories, predicts obstacles, and establishes success criteria for each phase.',
        output: `> CONSULTING THE ORACLE...
> Task: "Add user authentication"
> Generating stories...
├── Story 1: Setup auth provider
├── Story 2: Create login form
├── Story 3: Implement JWT tokens
├── Story 4: Add protected routes
> Risk assessment: LOW
> PROPHECY DELIVERED ✓`,
        time: '01:45'
    },
    build: {
        icon: '⚡',
        title: 'BUILD',
        agent: 'Drone Agent',
        function: 'Drone workers execute the plan by writing code. Each drone specializes in specific domains—frontend, backend, infrastructure. They work in parallel when possible, producing clean, tested implementations.',
        output: `> DEPLOYING DRONES...
> Drone-Alpha: src/auth/provider.ts
> Drone-Beta: src/components/Login.tsx
> Drone-Gamma: src/middleware/jwt.ts
> Lines written: 847
> Files created: 12
> Files modified: 5
> BUILD SEQUENCE COMPLETE ✓`,
        time: '15:00'
    },
    test: {
        icon: '🔬',
        title: 'TEST',
        agent: 'Probe Agent',
        function: 'Probes systematically test all new code paths. They run unit tests, integration tests, and simulate edge cases. Probes identify regressions and validate that implementations match specifications.',
        output: `> LAUNCHING PROBES...
> Unit tests: 47 passed, 0 failed
> Integration tests: 12 passed
> Coverage: 94.2%
> Edge cases validated: 8/8
> Performance check: PASSED
> Memory leaks: NONE DETECTED
> PROBE ANALYSIS COMPLETE ✓`,
        time: '03:20'
    },
    review: {
        icon: '👁️',
        title: 'REVIEW',
        agent: 'Overseer Agent',
        function: 'The Overseer performs final quality inspection. It reviews code style, architecture decisions, security implications, and ensures alignment with project conventions. The Overseer has veto power.',
        output: `> OVERSEER AWAKENED...
> Code style: COMPLIANT
> Architecture: APPROVED
> Security scan: NO VULNERABILITIES
> Performance impact: +2ms (acceptable)
> Documentation: PRESENT
> APPROVAL GRANTED ✓`,
        time: '02:00'
    },
    ship: {
        icon: '🚀',
        title: 'SHIP',
        agent: 'Beacon Agent',
        function: 'Beacon handles deployment and release. It creates pull requests, manages version bumps, triggers CI/CD pipelines, and broadcasts completion signals to stakeholders. The final phase of the mission.',
        output: `> BEACON ACTIVATED...
> Creating PR: #247
> Branch: feature/user-auth
> CI Pipeline: TRIGGERED
> Tests: ALL GREEN
> Deploy preview: https://pr-247.app
> Notification sent to: #dev-team
> MISSION ACCOMPLISHED 🎯`,
        time: '01:30'
    }
};

// DOM Elements
const steps = document.querySelectorAll('.step');
const detailsPanel = document.getElementById('detailsPanel');
const panelIcon = document.getElementById('panelIcon');
const panelTitle = document.getElementById('panelTitle');
const agentFunction = document.getElementById('agentFunction');
const outputTerminal = document.getElementById('outputTerminal');
const timeValue = document.getElementById('timeValue');
const progressFill = document.getElementById('progressFill');
const panelClose = document.getElementById('panelClose');
const starfield = document.getElementById('starfield');

// Current state
let activeStep = null;

// Initialize starfield
function createStarfield() {
    const numStars = 100;
    for (let i = 0; i < numStars; i++) {
        const star = document.createElement('div');
        star.className = 'star';
        star.style.left = Math.random() * 100 + '%';
        star.style.top = Math.random() * 100 + '%';
        star.style.width = Math.random() * 2 + 1 + 'px';
        star.style.height = star.style.width;
        star.style.animationDelay = Math.random() * 2 + 's';
        star.style.animationDuration = (Math.random() * 2 + 1) + 's';
        starfield.appendChild(star);
    }
}

// Calculate progress based on step
function getStepProgress(stepName) {
    const stepOrder = ['assimilate', 'plan', 'build', 'test', 'review', 'ship'];
    const index = stepOrder.indexOf(stepName);
    return ((index + 1) / stepOrder.length) * 100;
}

// Typewriter effect for terminal
function typeWriter(element, text, speed = 20) {
    element.innerHTML = '';
    let i = 0;
    const code = document.createElement('code');
    element.appendChild(code);
    
    function type() {
        if (i < text.length) {
            code.textContent += text.charAt(i);
            i++;
            setTimeout(type, speed);
        }
    }
    type();
}

// Show step details
function showStepDetails(stepName) {
    const data = stepData[stepName];
    if (!data) return;

    // Update active states
    steps.forEach(step => {
        step.classList.remove('active');
        if (step.dataset.step === stepName) {
            step.classList.add('active');
        }
    });

    // Update panel
    detailsPanel.classList.add('active');
    panelIcon.textContent = data.icon;
    panelTitle.textContent = `${data.title} // ${data.agent}`;
    agentFunction.textContent = data.function;
    timeValue.textContent = data.time;

    // Animate terminal output
    typeWriter(outputTerminal, data.output, 15);

    // Update progress bar
    progressFill.style.width = getStepProgress(stepName) + '%';

    activeStep = stepName;
}

// Close panel
function closePanel() {
    detailsPanel.classList.remove('active');
    steps.forEach(step => step.classList.remove('active'));
    progressFill.style.width = '0%';
    activeStep = null;
    
    // Reset panel content
    panelIcon.textContent = '🛸';
    panelTitle.textContent = 'SELECT A PHASE';
    agentFunction.textContent = 'Click on any phase node to view detailed intelligence.';
    outputTerminal.innerHTML = '<code>AWAITING SELECTION...</code>';
    timeValue.textContent = '--:--';
}

// Event listeners
steps.forEach(step => {
    step.addEventListener('click', () => {
        const stepName = step.dataset.step;
        if (activeStep === stepName) {
            closePanel();
        } else {
            showStepDetails(stepName);
        }
    });
});

panelClose.addEventListener('click', closePanel);

// Keyboard navigation
document.addEventListener('keydown', (e) => {
    const stepOrder = ['assimilate', 'plan', 'build', 'test', 'review', 'ship'];
    const currentIndex = activeStep ? stepOrder.indexOf(activeStep) : -1;

    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
        e.preventDefault();
        const nextIndex = (currentIndex + 1) % stepOrder.length;
        showStepDetails(stepOrder[nextIndex]);
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
        e.preventDefault();
        const prevIndex = currentIndex <= 0 ? stepOrder.length - 1 : currentIndex - 1;
        showStepDetails(stepOrder[prevIndex]);
    } else if (e.key === 'Escape') {
        closePanel();
    }
});

// Auto-demo mode (optional - cycles through steps)
let demoInterval = null;

function startDemo() {
    const stepOrder = ['assimilate', 'plan', 'build', 'test', 'review', 'ship'];
    let index = 0;
    
    showStepDetails(stepOrder[index]);
    
    demoInterval = setInterval(() => {
        index = (index + 1) % stepOrder.length;
        showStepDetails(stepOrder[index]);
    }, 4000);
}

function stopDemo() {
    if (demoInterval) {
        clearInterval(demoInterval);
        demoInterval = null;
    }
}

// Stop demo on user interaction
steps.forEach(step => {
    step.addEventListener('click', stopDemo);
});

// Initialize
createStarfield();

// Start with first step selected after a brief delay
setTimeout(() => {
    showStepDetails('assimilate');
}, 500);
