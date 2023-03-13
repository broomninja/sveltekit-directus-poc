import { sveltekit } from '@sveltejs/kit/vite';
import type { UserConfig } from 'vite';
import svg from '@poppanator/sveltekit-svg';

const svgPlugin = svg({
    includePaths: ['./src/lib/icons/'],
    svgoOptions: {
        multipass: true,
        plugins: [
            {
                name: 'preset-default',
                // by default svgo removes the viewBox which prevents svg icons from scaling
                // not a good idea! https://github.com/svg/svgo/pull/1461
                params: {
                    overrides: {
                        removeViewBox: false,
                    },
                },
            },
            'removeDimensions',
        ],
    },
})

const config: UserConfig = {
	plugins: [
        sveltekit(),
        svgPlugin, 
    ],
	test: {
		include: ['src/**/*.{test,spec}.{js,ts}']
	},
    resolve: {
		alias: {
			crypto: 'crypto-browserify',
		},
	},
};

// server.hmr.overlay to false

export default config;
