# flickr-vancouver-average-colour-80x24

## 2022-10-30
1\. Looks like the number of lines is wrong
```bash
 mlr --csv cut -f id,woeid,pathalias,datetaken 2022-10-28-has_geo-flickr-metadata.csv | wc -l
7251
```
compare with:
>D, [2022-10-30T08:52:10.752963 #84069] DEBUG -- : photos_to_retrieve:9524

2\. looks like woeids are the individual woeid, use code from to http://rolandtanglao.com/2017/10/14/p1-trying-to-fix-chinatown-map-by-removing-the-woeid-that-is-subclass-of-strathcona/ to get Vancouver woeids?
3\. Looks like the geo api explorer is broken, flakey or removed: See [Woe id in the flickr forums](https://www.flickr.com/help/forum/en-us/72157708955254091/): 
>OK, having played some more it just looks like parents and children are completely flaky.
>OK, having played some more it just looks like parents and children are completely flaky.
>
>If I keep reloading a location, sometimes it only has earth as a parent, sometimes the parents and no children, sometimes both parents and children.
>
>Anyhow when it unflakes itself it looks to be very useful.
## 2022-10-29

### Current plan:
1. for a given date get all flickr metadata  24*80 = 1092 random flickr photos geotagged vancouver, not tagged infographic, or infoviz, or screenshots or videos etc
2. download the thumbnails
3. make 80x24 average colour infographic
