<script lang="ts">
  import { page } from '$app/stores';

  $: isUserLoggedIn = !!$page.data?.user;

  export let buttonText: string;
  export let guestTooltip: string | undefined = undefined;
  export let loggedInUserTooltip: string | undefined = undefined;

</script>

<button type="button" class="group relative inline-block ml-0 py-2 px-4 justify-center items-center gap-2 rounded-md bg-blue-100 
    border border-transparent font-semibold text-blue-500 hover:text-white hover:bg-blue-500 focus:outline-none 
    focus:ring-2 ring-offset-white focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm 
    dark:focus:ring-offset-gray-800 dark:bg-gray-900 dark:hover:bg-blue-400 dark:text-white">
    <span>
        {buttonText}
    </span>
    <!-- Tooltip -->

    {#if isUserLoggedIn && !!loggedInUserTooltip}
    <span class="absolute block hidden group-hover:flex -left-10 -top-3 -translate-y-full w-40 px-3 py-2 bg-gray-500 rounded-lg
                    text-center font-normal justify-center text-white text-xs after:content-[''] after:absolute after:left-1/2 after:top-[100%] 
                    after:-translate-x-1/2 after:border-8 after:border-x-transparent after:border-b-transparent after:border-t-gray-500">
        {loggedInUserTooltip}
    </span>
    {/if}

    {#if !isUserLoggedIn && !!guestTooltip}
    <span class="absolute block hidden group-hover:flex -left-10 -top-3 -translate-y-full w-40 px-3 py-2 bg-gray-500 rounded-lg
                    text-center font-normal justify-center text-white text-xs after:content-[''] after:absolute after:left-1/2 after:top-[100%] 
                    after:-translate-x-1/2 after:border-8 after:border-x-transparent after:border-b-transparent after:border-t-gray-500">
        {guestTooltip}
    </span>
    {/if}

    <!-- End Tooltip -->
</button>

<style>
/*  TODO: move span class to below
.button-tooltip {
}
*/
</style>