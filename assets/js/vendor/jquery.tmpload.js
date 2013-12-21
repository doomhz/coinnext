/**
* jQuery Tmpload Plugin v3.0
*
* Load and cache asyncronously local and remote jQuery templates
*
*
* @author Dumitru Glavan
* @link http://dumitruglavan.com
* @version 3.0 (20-OCT-2011)
* @requires jQuery v1.6 or later
*
* Find source on GitHub: https://github.com/doomhz/tmpload
*
* This content is released under the MIT License
*   http://www.opensource.org/licenses/mit-license.php
*
*/
(function($) {
    
    $.tmpload = function (options) {
        var self = this, html = null;
        
        options = $.extend({}, $.tmpload.defaults, options);
        
        // Cache a template in the memory
        self.cacheTemplate = function (cacheId, content) {
            $.tmpload.templates[cacheId] = content;
            return cacheId;
        };
        
        // Get a template from memory cache
        self.getCachedTemplate = function (cacheId) {
            return $.tmpload.templates[cacheId];
        };
        
        // Find a template in the DOM, load and cache it
        // Compile the template if a template engine specified
        self.loadLocalTemplate = function (templateId, cacheTemplate, tplWrapper) {
            var $localTemplate = $('#' + templateId);
            
            if ($localTemplate.length) {
                html = self.decodeHtml($localTemplate.html());
                html = tplWrapper ? tplWrapper(html) : html;
                cacheTemplate && self.cacheTemplate(templateId, html);
                return html;
            } else {
                var exception = {
                    name: 'Template not found',
                    error: 'A local template with the id "' + options.id + '" could not be found in the DOM.'
                };
                throw exception;
            }
        };
        
        // Request a remote template, load and cache it
        // Compile the template if a template engine specified
        self.loadRemoteTemplate = function (templateUrl, loadCallback, cacheTemplate, tplWrapper) {
            return $.ajax({
                        url: templateUrl,
                        success: function (response) {
                            response = self.decodeHtml(response);
                            response = tplWrapper ? tplWrapper(response) : response;
                            cacheTemplate && self.cacheTemplate(templateUrl, response);
                            return $.isFunction(loadCallback) && loadCallback.call(self, response);
                        }
                    });
        };

        // Decode the template HTML tags if any
        self.decodeHtml = function (html) {
            return html.replace(/&gt;/g, '>').replace(/&lt;/g, '<');
        };
        
        // Make a template id work without #
        options.id = options.id && options.id.replace(/^#/, '');
        
        // Decide how to load the template - by id or url
        var cacheKey = options.url || options.id;
        
        // Throw an exceptino if no id or url is specified
        if (!cacheKey) {
            throw {
                name: 'Invalid template',
                error: 'A template name or url should be specified.'
            };
        }
        
        // Search for a cached template if wanted
        if (options.cache) {
            html = self.getCachedTemplate(cacheKey);
            if (html) {
                if ($.isFunction(options.onLoad)) {
                    return options.onLoad.call(self, html);
                }
                return html;
            }
        }
        
        // Grab a remote template or a local one
        if (options.url) {
            return self.loadRemoteTemplate(options.url, options.onLoad, options.cache, options.tplWrapper);
        } else {
            return self.loadLocalTemplate(options.id, options.cache, options.tplWrapper);
        }
    };
    
    // Cache container
    $.tmpload.templates = {};
    
    // Default options
    $.tmpload.defaults = {
        id: null,
        url: null,
        cache: true,
        onLoad: null,
        tplWrapper: null
    };
    
})(jQuery);