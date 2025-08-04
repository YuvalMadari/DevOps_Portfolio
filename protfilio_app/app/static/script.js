    const form = document.getElementById("toolForm");
    const result = document.getElementById("result");
    const deleteBtn = document.getElementById("deleteBtn");
    const fetchBtn = document.getElementById("fetchBtn");

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const name = form.name.value;
      const definition = form.definition.value;

      const formData = new FormData();
      formData.append('name', name);
      formData.append('definition', definition);

      const res = await fetch(`/tool/${name}`, {
        method: "PUT",
        body: formData,
      });

      const html = await res.text();
      // Extract the cow message from the returned HTML
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');
      const cowMessage = doc.getElementById('result').textContent;
      result.textContent = cowMessage;
    });

    deleteBtn.addEventListener("click", async () => {
      const name = form.name.value;
      if (!name) {
        result.textContent = "Please enter a tool name to delete.";
        return;
      }
      
      const res = await fetch(`/tool/${name}`, { method: "DELETE" });
      const html = await res.text();
      // Extract the cow message from the returned HTML
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');
      const cowMessage = doc.getElementById('result').textContent;
      result.textContent = cowMessage;
    });

    fetchBtn.addEventListener("click", async () => {
      const name = form.name.value;
      if (!name) {
        result.textContent = "Please enter a tool name to search.";
        return;
      }
      
      const res = await fetch(`/tool/${name}`);
      const html = await res.text();
      // Extract the cow message from the returned HTML
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');
      const cowMessage = doc.getElementById('result').textContent;
      result.textContent = cowMessage;
    });