<script lang="ts">
	import { loading, LoadingStatus } from '$lib/store/loadingStore';
	import PageSpinner from './PageSpinner.svelte';
	$: if ($loading.status === LoadingStatus.NAVIGATING) {
		setTimeout(() => {
			if ($loading.status === LoadingStatus.NAVIGATING) {
				$loading.status = LoadingStatus.LOADING;
			}
		}, $loading.delay);
	}
</script>

{#if $loading.status === LoadingStatus.LOADING}
	<div class="overlay">
		<PageSpinner />
        {#if !!$loading.message}
		    <span>{$loading.message}</span>
	    {/if}
    </div>
{/if}

<style lang="postcss">
	.overlay {
		@apply flex justify-center items-center fixed top-0 right-0 left-0 w-[100vw] h-screen bg-neutral-200/50 z-[10000];
	}
</style>