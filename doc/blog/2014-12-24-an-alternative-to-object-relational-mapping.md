<div class="blog-post-date">2014, December 24</div>

# An alternative to Object Relational Mapping (ORM)

Now that we have [database viewpoints as background](/2014-12-12-context-aware-database-viewpoints), I'd like to share a real example of what the [Relations as First-class Citizen](2013-10-21-relations-as-first-class-citizen) paradigm is about. In this blog post, I build a small yet not trivial application to illustrate how Alf can be used as an nice alternative to Object Relational Mapping.

The case study, borrowed from a scientific paper by former colleagues of mine, is chosen to illustrate how somewhat complex data requirements can be disentangled easily with relational thinking, a witness of the simplicity seeked by most. The case-study is also detailed here so that you can challenge *your* favorite approach. Maybe you can document it for further comparisons and discussion?

## Case-study: Mobile City

The case study chosen here is taken from the following paper:

> Sergio Castro et al. "DynamicSchema: a lightweight persistency framework for context-oriented data management." Proceedings of the International Workshop on Context-Oriented Programming. ACM, 2012.

### Description (from the paper above)

The case study involves an application called *MobileCity* whose objective is to help and inform tourists when visiting an unknown city.

Among others, the *MobileCity* application offers tourist information on various points of interest (POIs) in a city. Each POI has a (textual) description, an image, as well as some other attributes. As for a POI, each image has a textual description associated with it as well. Furthermore, POIs are organized hierarchically according to their location. For example, the POI Brussels is a child of the POI Belgium. The latter, being a root POI of the application, does not have a parent POI.

Each user of the application has its own user profile, which contains among others the preferred language of the user and his age group. The age group can have only two possible
values for now: *adult* and *child*. This profile influences the actual description that should be shown when browsing the information on POIs and images, so that the language and age group of the description match with those in the user profile. For example, if the user speaks French and is of the age group child, the application will use child-friendly
descriptions in French for the POIs and images being shown.

All users have access to a list of predefined POIs (for example, encoded by the tourist office), but they can also add their own new POIs to the database. Newly defined POIs are accessible only to the user profiles under which they were created, since probably they are not of interest to other users of the application. Already existing POIs, on the other hand, are accessible to all users of the application and belong to a Default user profile.

Finally, there is an important security concern. Certain POIs can be marked as restricted (e.g. bars serving alcohol), which means that they should never appear when browsed by a user whose profile belongs to the child age group.

### Data visibility requirements

From the original problem description, one can easily extract the following data visibility requirements:

1. POI and image descriptions shall be served in the user's language.
2. POI and image descriptions shall be adapted to the user's age group.
3. Newly created POIs shall be visible by their owner only.
4. Restricted POIs shall not be visible by children.

There are of course other requirements regarding the creation and publication of POIs, e.g., those stating who is allowed to create POIs, how are all translations handled, who can mark POIs as restricted, and so on. We will simply ignore them in the blog post for two reasons:

* The original problem description does not explicitly cover those.
* Relational algebra (Alf's real focus) is not of much help regarding software operations and database updates. That does not mean there are nothing to say here, but it is simply out of scope of this particular blog post.

Even when ignoring updates, a quick analysis of the data visibility requirements above reveals another issue. Four requirements already yield a potential conflict: *What if a child owns a restricted POI?* Requirement 4 seems to suggest that the POI should be visible, while Requirement 5 prevents it from being visible. Resolving this conflict is  simple: let for example choose that R5 takes over R4. It is however representative of the kind of complexity we want to tackle: what if we change our mind later? How can the software development approach help disentangling requirements? How can it help changing our mind easily? We will see later how composable viewpoints help.

### Scope & Assumptions

The specification and implementation of the entire *MobileCity* case study is of course out of scope of this blog post. To keep the discussion short enough, we will consider the scope illustrated on the figure below:

![Overview of the scope](/blogging/2014-12-24-an-alternative-to-object-relational-mapping/overview.png)

Given a mobile frontend, the user can authenticate to the backend. Once authenticated, it (asks and) receives the list of points of interest to be displayed to the user. That returned list shall of course meet the requirements of the previous section.