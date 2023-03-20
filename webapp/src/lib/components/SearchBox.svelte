<script lang="ts">
    import { tick } from "svelte";
    import { afterNavigate } from '$app/navigation';
    import debounce from 'just-debounce-it';
    import SearchIcon from '$lib/icons/search.svg?component';
    import CrossIcon from '$lib/icons/cross.svg?component';
    import CardFeedbackSearch from '$lib/components/CardFeedbackSearch.svelte';

    let searchDropdownElement;
    let searchQuery = '';
    let searchResult = {};
    let isLoading = false;

    const debounceDelay = 420; // in ms
    
    const fetchSearchResult = debounce(async () => {
        isLoading = true;

        const data = { query: searchQuery };
        const response = await fetch('/api/search', {
            method: 'POST',
            body: JSON.stringify(data),
            headers: {
                'content-type': 'application/json',
            },
        });

        const body = await response.json();
        searchResult = body.result;

        // make sure search dropdown is displayed upon new search results.
        // the dropdown could be hidden (due to resize events or other events) 
        // or user has used tab to navigate to the search box so still has keyboard 
        // focus, when he types any new search query the results won't be displayed 
        // if we dont call HSDropdown.open
        // see https://preline.co/plugins/html/dropdown.html#js-methods
        openDropdown();

        isLoading = false;
    }, debounceDelay);

    const handleSubmit = async () => {
        await tick();

        if (!searchQuery || searchQuery.trim().length === 0) {
            searchResult = {};
            return;
        }
        
        fetchSearchResult();
    };

    const openDropdown = debounce(() => {
        if (!!searchQuery && searchQuery.trim().length > 0) {
            window.HSDropdown.open(searchDropdownElement);
        }
    }, 100);

    const closeDropdown = debounce(() => {
        window.HSDropdown.close(searchDropdownElement);
    }, 100);

    const resetSearch = () => {
        searchQuery = '';
        searchResult = {};
    };

    afterNavigate(({ from, to, type, willUnload }) => {
        resetSearch();
    });

</script>

<div bind:this={searchDropdownElement} class="hs-dropdown relative inline-flex [--auto-close:false] [--trigger:click] ">
    <label for="query" class="sr-only">Search</label>
    <div class="relative">
        {#if isLoading}
        <div class="absolute inset-y-0 left-0 flex items-center pointer-events-none pl-4">
            <div class="animate-spin inline-block w-4 h-4 border-[3px] border-current border-t-transparent text-blue-600 rounded-full" role="status" aria-label="loading">
                <span class="sr-only">Loading...</span>
            </div>
        </div>
        {:else}
        <div class="absolute inset-y-0 left-0 flex items-center pointer-events-none pl-4">
            <SearchIcon />
        </div>
        {/if}

        <input 
            id="query"
            type="text"
            name="query"
            placeholder="Search" 
            autocomplete="off"
            autocorrect="off"
            autocapitalize="off"
            spellcheck="false"
            on:input={handleSubmit}
            on:focus={openDropdown}
            on:blur={closeDropdown}
            bind:value={searchQuery}
            class="py-2 px-4 pl-11 block w-full border border-gray-300 shadow-sm rounded-md text-sm 
                focus:z-[200] focus:border-blue-500 focus:ring-blue-500 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400" 
        />
        {#if !!searchQuery}
        <div role="presentation" on:click={()=>resetSearch()} 
             class="absolute inset-y-0 right-0 flex items-center pointer-events-auto px-1 mx-1 my-2 text-gray-400">
            <CrossIcon />
        </div>
        {/if}
    </div>
    <div class="hs-dropdown-menu overflow-y-scroll w-80 h-60 transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 
                hidden z-[200] top-0 lg:left-auto lg:right-0 min-w-[16.5rem] bg-white shadow-md rounded-lg p-3 mt-20 border border-gray-300 
                dark:bg-gray-800 dark:border dark:border-gray-700 dark:divide-gray-700" aria-labelledby="hs-dropdown-right-but-left-on-lg">
        {#if !!searchResult && Object.keys(searchResult).length > 0}
        <div class="grid">
            {#each searchResult.hits as feedback}
                <div>
                    <CardFeedbackSearch {feedback} />
                </div>
            {:else}
                No results found
            {/each}
        </div>
        {:else}
        <div class="text-left">
            Type to start searching ...
        </div>
        {/if}
    </div>
</div>
