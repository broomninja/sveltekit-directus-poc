<script lang="ts">
	import { page } from '$app/stores';
	function resolveErrorCode(code: number) {
		switch (code) {
			case 404:
				return {
					code,
					title: 'Page not found',
					subtitle: $page.error?.message || 'The page you are looking for does not exist.',
					advice: "Try using the menu to find what you're looking for.",
				};
			case 500:
				return {
					code,
					title: 'Internal server error',
					subtitle: $page.error?.message || 'Something went wrong on our end.',
					advice: "It's not you, it's us. Try refreshing the page or come back later.",
				};
			default:
				return {
					code,
					title: 'Unknown error',
					subtitle: $page.error?.message || 'Something went wrong.',
				};
		}
	}
	$: error = resolveErrorCode($page.status);
</script>
<div class="py-10">
	<div size="small" class="rounded-2xl bg-white py-16 px-6 text-center sm:py-20 lg:px-8">
		<h2 class="">
			<span class="text-label block tracking-widest text-red-600 sm:text-base">
				Error {error.code}<span class="sr-only">:</span>
			</span>
			<span class="text-3xl font-bold tracking-tight text-red-900 sm:text-4xl">
				{error.title}
			</span>
		</h2>
		<p class="mt-4 text-base leading-6 text-red-900/70 lg:text-lg">
			{error.subtitle}
		</p>
		{#if error.advice}
			<p
				class="mt-4 inline-block rounded-full bg-white px-4 py-1 text-base leading-6 text-red-600"
			>
				{error.advice}
			</p>
		{/if}
	</div>
</div>
